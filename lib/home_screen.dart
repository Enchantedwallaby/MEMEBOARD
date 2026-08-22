import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<QuerySnapshot> _memesStream;

  @override
  void initState() {
    super.initState();
    _memesStream = FirebaseFirestore.instance
        .collection('memes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _toggleLike(DocumentSnapshot meme) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('memes').doc(meme.id);
    final data = meme.data() as Map<String, dynamic>;
    final List likes = List.from(data['likes'] ?? []);

    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }

    await ref.update({'likes': likes});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
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
        title: Row(
          children: [
            Image.asset(
              'assets/memeboard-logo_8b8c24a4.png',
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'MemeBoard',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _memesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😴', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'No memes yet.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to drop one! 🔥',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }

          final memes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: memes.length,
            itemBuilder: (context, index) {
              final meme = memes[index];
              final data = meme.data() as Map<String, dynamic>;
              final List likes = List.from(data['likes'] ?? []);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final isLiked = uid != null && likes.contains(uid);
              final caption = data['caption'] as String? ?? '';
              final poster = data['posterEmail'] as String? ?? '';
              final ts = data['timestamp'] as Timestamp?;
              final timeStr = ts != null
                  ? _formatTime(ts.toDate())
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row
                    if (poster.isNotEmpty || timeStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                poster.isNotEmpty ? poster : 'Anonymous',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Meme Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(0),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: data['url'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 220,
                          color: const Color(0xFFF3E8FF),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 220,
                          color: const Color(0xFFF3E8FF),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFF7C3AED),
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Caption + Like row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: caption.isNotEmpty
                                ? Text(
                                    caption,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          // Like button
                          GestureDetector(
                            onTap: () => _toggleLike(meme),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isLiked
                                    ? const Color(0xFFFCE7F3)
                                    : const Color(0xFFF9F5FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isLiked
                                      ? const Color(0xFFF43F5E)
                                      : const Color(0xFFE9D5FF),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked
                                        ? const Color(0xFFF43F5E)
                                        : const Color(0xFF7C3AED),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${likes.length}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isLiked
                                          ? const Color(0xFFF43F5E)
                                          : const Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
