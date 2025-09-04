// post_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  Uint8List? _compressedBytes; // for preview + upload
  final captionController = TextEditingController();

  bool isUploading = false;
  double uploadProgress = 0.0;
  UploadTask? _uploadTask;

  // Pick image and compress it
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _pickedFile = picked;
      _compressedBytes = null;
    });

    final rawBytes = await picked.readAsBytes();

    // Compress/rescale (adjust maxWidth / quality as needed)
    final bytes = await compute(_compressImageBytes, CompressorParams(rawBytes, 1024, 80));
    setState(() {
      _compressedBytes = bytes;
    });
  }

  // Upload compressed bytes and show progress
  Future<void> uploadMeme() async {
    if (_compressedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an image first')));
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('memes/$fileName.jpg');

    try {
      // detect mime type (fallback to jpeg)
      final contentType = lookupMimeType('', headerBytes: _compressedBytes) ?? 'image/jpeg';
      final metadata = SettableMetadata(contentType: contentType);

      _uploadTask = ref.putData(_compressedBytes!, metadata);

      _uploadTask!.snapshotEvents.listen((snapshot) {
        final transferred = snapshot.bytesTransferred;
        final total = snapshot.totalBytes;
        if (total > 0) {
          setState(() => uploadProgress = transferred / total);
        }
      }, onError: (e) {
        // handle errors here if needed
      });

      final snapshot = await _uploadTask!;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // save to Firestore
      await FirebaseFirestore.instance.collection('memes').add({
        'url': downloadUrl,
        'caption': captionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded successfully')));
      setState(() {
        _pickedFile = null;
        _compressedBytes = null;
        captionController.clear();
        isUploading = false;
        uploadProgress = 0.0;
      });
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      _uploadTask = null;
    }
  }

  // Allow canceling
  void cancelUpload() {
    _uploadTask?.cancel();
    setState(() {
      isUploading = false;
      uploadProgress = 0.0;
      _uploadTask = null;
    });
  }

  Widget buildImagePreview() {
    if (_pickedFile == null) {
      return GestureDetector(
        onTap: pickImage,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[200]),
          child: const Center(child: Text('Tap to pick meme image')),
        ),
      );
    }

    // Use compressed bytes for preview if available (better)
    if (_compressedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_compressedBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    }

    // Fallback (shouldn't happen often)
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: kIsWeb
          ? Image.network(_pickedFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
          : Image.file(File(_pickedFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
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
      appBar: AppBar(title: const Text('Post Meme'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildImagePreview(),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              decoration: InputDecoration(
                hintText: 'Add a caption (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            if (isUploading)
              Column(children: [
                LinearProgressIndicator(value: uploadProgress),
                const SizedBox(height: 8),
                Text('${(uploadProgress * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: cancelUpload, child: const Text('Cancel Upload')),
              ])
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_compressedBytes == null || isUploading) ? pickImage : uploadMeme,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isUploading ? 'Uploading...' : (_compressedBytes == null ? 'Pick Image' : 'Upload Meme'),
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// top-level helper to run compression off the UI thread via compute
class CompressorParams {
  final Uint8List bytes;
  final int maxWidth;
  final int quality;
  CompressorParams(this.bytes, this.maxWidth, this.quality);
}

// This runs in a background isolate (compute)
Uint8List _compressImageBytes(CompressorParams p) {
  final data = p.bytes;
  final img = img_pkg.decodeImage(data);
  if (img == null) return data;

  // calculate target width keeping aspect ratio
  final int targetWidth = img.width > p.maxWidth ? p.maxWidth : img.width;
  final resized = img_pkg.copyResize(img, width: targetWidth);
  final jpg = img_pkg.encodeJpg(resized, quality: p.quality);
  return Uint8List.fromList(jpg);
}
