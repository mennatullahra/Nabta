import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/kid_background.dart';
import '../widgets/app_image.dart';

class ProgressScreen extends StatelessWidget {
  final AppUser user;
  const ProgressScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final completedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('completedLessons')
        .orderBy('completedAt', descending: true);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('My progress',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: KidBackground(
        colors: const [Color(0xFF43B97F), Color(0xFF8BE0B4)],
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: completedRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              final docs = snapshot.data?.docs ?? [];
              final count = docs.length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Column(
                    children: [
                      const AppImage('trophy.png',
                          width: 120, placeholderEmoji: '🏆'),
                      const SizedBox(height: 6),
                      Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 16),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$count',
                                style: const TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.seed)),
                            const Text('lessons',
                                style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(count == 0 ? 'Let\'s begin! 🚀' : 'Great work! 🎉',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _BadgeRow(count: count),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: docs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No lessons finished yet.\nTap "Mark as complete" in a lesson to earn your first star! ⭐',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : Column(
                            children: docs.map((d) {
                              final data = d.data() as Map<String, dynamic>;
                              final title =
                                  (data['lessonTitle'] as String?) ?? 'Lesson';
                              final ts = data['completedAt'] as Timestamp?;
                              final when = ts != null
                                  ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                                  : '';
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.seed,
                                  child: Icon(Icons.star_rounded,
                                      color: Colors.white),
                                ),
                                title: Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text('Completed on $when'),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final int count;
  const _BadgeRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final milestones = [1, 5, 10, 25];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: milestones.map((m) {
        final earned = count >= m;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Opacity(
                opacity: earned ? 1 : 0.4,
                child: Text(earned ? '🌟' : '⚪',
                    style: const TextStyle(fontSize: 24)),
              ),
              Text('$m',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
