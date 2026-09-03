import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/course.dart';
import 'lessons_screen.dart';
import '../models/app_user.dart';
import 'create_course_screen.dart';

class CoursesScreen extends StatelessWidget {
  final Subject subject;
  final AppUser user;
  const CoursesScreen({super.key, required this.subject, required this.user});

  Future<void> _confirmDeleteCourse(BuildContext context, Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('"${course.title}" will be removed.'),
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
      await FirebaseFirestore.instance.collection('courses').doc(course.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only courses whose subjectId matches this subject.
    final coursesQuery = FirebaseFirestore.instance
        .collection('courses')
        .where('subjectId', isEqualTo: subject.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: user.isTeacher
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateCourseScreen(
                      subject: subject,
                      user: user,
                    ),
                  ),
                );
              },
              tooltip: 'New course',
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: coursesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No courses yet.\nTap + to add one.',
                  textAlign: TextAlign.center),
            );
          }
          final courses = docs
              .map((doc) =>
                  Course.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline, size: 36),
                  title: Text(course.title),
                  subtitle: Text('${course.teacherName} · ${course.gradeLevel}'),
                  trailing: user.isTeacher
                      ? PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => CreateCourseScreen(
                                    subject: subject, user: user, existing: course),
                              ));
                            } else if (v == 'delete') {
                              _confirmDeleteCourse(context, course);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : (course.isPremium
                          ? const Icon(Icons.lock, size: 18)
                          : const Text('Free')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LessonsScreen(course: course, user: user)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}