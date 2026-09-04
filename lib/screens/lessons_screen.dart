import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'lesson_detail_screen.dart';
import 'create_lesson_screen.dart';

class LessonsScreen extends StatelessWidget {
  final Course course;
  final AppUser user;
  const LessonsScreen({super.key, required this.course, required this.user});

  CollectionReference<Map<String, dynamic>> get _lessonsRef =>
      FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .collection('lessons');

  Future<void> _confirmDeleteLesson(BuildContext context, Lesson lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete lesson?'),
        content: Text('"${lesson.title}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _lessonsRef.doc(lesson.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      floatingActionButton: user.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateLessonScreen(course: course, user: user),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New lesson'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('completedLessons')
            .snapshots(),
        builder: (context, progressSnap) {
          final completed = <String>{};
          if (progressSnap.hasData) {
            for (final d in progressSnap.data!.docs) {
              completed.add(d.id);
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _lessonsRef.orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 54)),
                      const SizedBox(height: 12),
                      Text(
                        user.isTeacher
                            ? 'No lessons yet.\nTap + to create your first one.'
                            : 'No lessons here yet.\nCheck back soon!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }
              final lessons = docs
                  .map((d) =>
                      Lesson.fromMap(d.id, d.data() as Map<String, dynamic>))
                  .toList();
              final doneCount =
                  lessons.where((l) => completed.contains(l.id)).length;
              final pct = doneCount / lessons.length;

              return Column(
                children: [
                  if (!user.isTeacher)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pct == 1.0
                                    ? 'All done! 🏆'
                                    : 'Your progress',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text('$doneCount / ${lessons.length}',
                                  style: const TextStyle(
                                      color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 12,
                              backgroundColor: const Color(0xFFE8F1E8),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.seed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        final isDone = completed.contains(lesson.id);
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            leading: Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTheme.seed
                                    : AppTheme.sky.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(Icons.star_rounded,
                                        color: Colors.white, size: 28)
                                    : Text('${lesson.order}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.sky,
                                            fontSize: 18)),
                              ),
                            ),
                            title: Text(lesson.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${lesson.keyPoints.length} key points · ${lesson.questions.length} questions'),
                            trailing: user.isTeacher
                                ? PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CreateLessonScreen(
                                              course: course,
                                              user: user,
                                              existing: lesson,
                                            ),
                                          ),
                                        );
                                      } else if (v == 'delete') {
                                        _confirmDeleteLesson(context, lesson);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete')),
                                    ],
                                  )
                                : const Icon(Icons.chevron_right,
                                    color: Colors.black26),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonDetailScreen(
                                    lesson: lesson, user: user),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
