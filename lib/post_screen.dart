// post_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedFile;
  Uint8List? _compressedBytes;
  final captionController = TextEditingController();

  bool isUploading = false;
  double uploadProgress = 0.0;
  UploadTask? _uploadTask;

  // Pick image and compress it
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      _pickedFile = picked;
      _compressedBytes = null;
    });

    final rawBytes = await picked.readAsBytes();
    final bytes = await compute(
      _compressImageBytes,
      CompressorParams(rawBytes, 1024, 80),
    );
    if (!mounted) return;
    setState(() {
      _compressedBytes = bytes;
    });
  }

  // Upload compressed bytes and show progress
  Future<void> uploadMeme() async {
    if (_compressedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an image first')),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('memes/$fileName.jpg');

    try {
      final contentType =
          lookupMimeType('', headerBytes: _compressedBytes) ?? 'image/jpeg';
      final metadata = SettableMetadata(contentType: contentType);

      _uploadTask = ref.putData(_compressedBytes!, metadata);

      _uploadTask!.snapshotEvents.listen((snapshot) {
        final transferred = snapshot.bytesTransferred;
        final total = snapshot.totalBytes;
        if (total > 0) {
          if (!mounted) return;
          setState(() => uploadProgress = transferred / total);
        }
      }, onError: (_) {});

      final snapshot = await _uploadTask!;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      await FirebaseFirestore.instance.collection('memes').add({
        'url': downloadUrl,
        'caption': captionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'posterEmail': userEmail,
        'likes': [],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('🔥  Meme uploaded! Go viral.'),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() {
        _pickedFile = null;
        _compressedBytes = null;
        captionController.clear();
        isUploading = false;
        uploadProgress = 0.0;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      _uploadTask = null;
    }
  }

  void cancelUpload() {
    _uploadTask?.cancel();
    if (mounted) {
      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
        _uploadTask = null;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_pickedFile == null) {
      return GestureDetector(
        onTap: pickImage,
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F5FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC084FC),
              width: 2,
              // dashed border effect via custom painter omitted for simplicity
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap to pick your meme',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'JPEG, PNG, GIF supported',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_compressedBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              _compressedBytes!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Change button overlay
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Change',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Fallback
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: kIsWeb
          ? Image.network(
              _pickedFile!.path,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(_pickedFile!.path),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Text(
          'Post a Meme',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image picker area
            _buildImagePreview(),
            const SizedBox(height: 20),

            // Caption input
            TextField(
              controller: captionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Caption',
                labelStyle: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'Say something funny... (optional)',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF7C3AED),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),

            // Upload progress
            if (isUploading) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Uploading meme... 🚀',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        Text(
                          '${(uploadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: uploadProgress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE9D5FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: cancelUpload,
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Color(0xFFEF4444),
                      ),
                      label: const Text(
                        'Cancel Upload',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Action button — gradient
              SizedBox(
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _compressedBytes != null
                          ? [const Color(0xFF7C3AED), const Color(0xFF06B6D4)]
                          : [const Color(0xFFC4B5FD), const Color(0xFF93C5FD)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _compressedBytes != null
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : [],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _compressedBytes == null ? pickImage : uploadMeme,
                    icon: Icon(
                      _compressedBytes == null
                          ? Icons.add_photo_alternate
                          : Icons.rocket_launch,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: Text(
                      _compressedBytes == null ? 'Pick Image' : 'Upload Meme 🔥',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// top-level helper for isolate-based compression
class CompressorParams {
  final Uint8List bytes;
  final int maxWidth;
  final int quality;
  CompressorParams(this.bytes, this.maxWidth, this.quality);
}

Uint8List _compressImageBytes(CompressorParams p) {
  final data = p.bytes;
  final img = img_pkg.decodeImage(data);
  if (img == null) return data;

  final int targetWidth = img.width > p.maxWidth ? p.maxWidth : img.width;
  final resized = img_pkg.copyResize(img, width: targetWidth);
  final jpg = img_pkg.encodeJpg(resized, quality: p.quality);
  return Uint8List.fromList(jpg);
}
