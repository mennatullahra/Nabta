import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/kid_helpers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';
import 'courses_screen.dart';
import 'progress_screen.dart';

class SubjectsScreen extends StatelessWidget {
  final AppUser user;
  const SubjectsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final subjectsQuery =
        FirebaseFirestore.instance.collection('subjects').orderBy('order');
    final firstName =
        user.name.trim().isEmpty ? 'friend' : user.name.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF3FAFF),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: subjectsQuery.snapshots(),
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            final docs = snapshot.data?.docs ?? [];
            final subjects = docs
                .map((doc) => Subject.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>))
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 8),
                        Text('Hi, $firstName!',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        if (!user.isTeacher)
                          IconButton(
                            icon: const Icon(Icons.emoji_events_rounded,
                                color: AppTheme.sun),
                            tooltip: 'My progress',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProgressScreen(user: user)),
                            ),
                          ),
                        if (user.isTeacher)
                          const Chip(
                            label: Text('Teacher'),
                            visualDensity: VisualDensity.compact,
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.black45),
                          tooltip: 'Log out',
                          onPressed: () => AuthService().signOut(),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---- hero banner with hippo mascot ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63E0), Color(0xFF8E86F0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Let's learn today!",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(height: 6),
                                Text('Pick a subject and start playing 🎈',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                          const AppImage('hippo.png',
                              width: 96, placeholderEmoji: '🦛'),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text('Subjects',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withValues(alpha: 0.75))),
                  ),
                ),

                if (loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (subjects.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No subjects yet.\nCheck back soon!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.98,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = subjects[index];
                          return _SubjectTile(
                            subject: subject,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CoursesScreen(
                                    subject: subject, user: user),
                              ),
                            ),
                          );
                        },
                        childCount: subjects.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  const _SubjectTile({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = subjectColor(subject.iconColor);
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 78,
                width: 78,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(subjectEmoji(subject.name),
                      style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 12),
              Text(subject.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(subject.nameAr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
