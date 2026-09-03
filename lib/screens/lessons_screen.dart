import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../models/app_user.dart';
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
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
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
      appBar: AppBar(
        title: Text(course.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: user.isTeacher
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateLessonScreen(course: course, user: user),
                  ),
                );
              },
              tooltip: 'New lesson',
              child: const Icon(Icons.add),
            )
          : null,
      // Outer stream: this user's completed-lesson records.
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

          // Inner stream: the lessons.
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
                return _EmptyState(
                  icon: Icons.menu_book_outlined,
                  message: user.isTeacher
                      ? 'No lessons yet.\nTap + to create your first one.'
                      : 'No lessons here yet.\nCheck back soon!',
                );
              }
              final lessons = docs
                  .map((d) =>
                      Lesson.fromMap(d.id, d.data() as Map<String, dynamic>))
                  .toList();
              final doneCount =
                  lessons.where((l) => completed.contains(l.id)).length;

              return Column(
                children: [
                  if (!user.isTeacher)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$doneCount of ${lessons.length} lessons complete',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: doneCount / lessons.length,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        final isDone = completed.contains(lesson.id);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDone ? Colors.green : null,
                              child: isDone
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : Text('${lesson.order}'),
                            ),
                            title: Text(lesson.title),
                            subtitle: Text(
                                '${lesson.keyPoints.length} key points · ${lesson.questions.length} questions'),
                            trailing: user.isTeacher
                                ? PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CreateLessonScreen(
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
                                          value: 'delete', child: Text('Delete')),
                                    ],
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LessonDetailScreen(
                                      lesson: lesson, user: user),
                                ),
                              );
                            },
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }
}