import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/course.dart';
import 'lessons_screen.dart';

class CoursesScreen extends StatelessWidget {
  final Subject subject;
  const CoursesScreen({super.key, required this.subject});

  // Temporary: adds one sample course to THIS subject.
  Future<void> _addSampleCourse() async {
    final course = Course(
      id: '',
      subjectId: subject.id,          // the link to this subject
      teacherId: 'temp_teacher_1',
      teacherName: 'Ms. Sara',        // the copied name
      title: 'Introduction to ${subject.name}',
      description: 'A friendly starter course.',
      gradeLevel: 'Grade 4',
      isPremium: false,
      price: 0,
      lessonCount: 0,
    );
    await FirebaseFirestore.instance.collection('courses').add(course.toMap());
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addSampleCourse,
        tooltip: 'Add sample course',
        child: const Icon(Icons.add),
      ),
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
                  trailing: course.isPremium
                      ? const Icon(Icons.lock, size: 18)
                      : const Text('Free'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LessonsScreen(course: course)),
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