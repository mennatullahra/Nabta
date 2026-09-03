import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatelessWidget {
  final Course course;
  const LessonsScreen({super.key, required this.course});

  // 👇 THE NEW IDEA: lessons live INSIDE a specific course.
  //    Path in Firestore: courses/{courseId}/lessons
  CollectionReference<Map<String, dynamic>> get _lessonsRef =>
      FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .collection('lessons');

  Future<void> _addSampleLesson() async {
    final existing = await _lessonsRef.get();
    final nextOrder = existing.docs.length + 1;
    final lesson = Lesson(
      id: '',
      order: nextOrder,
      title: 'Lesson $nextOrder: Getting started',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      keyPoints: [
        'A number is a way to count and measure.',
        'Addition means putting groups together.',
        'The plus sign (+) tells us to add.',
      ],
      cards: [
        LessonCard(front: 'What does + mean?', back: 'It means add / put together.'),
        LessonCard(front: '2 + 3 = ?', back: '5'),
      ],
      questions: [
        QuizQuestion(question: 'What is 4 + 5?', options: ['7', '8', '9', '10'], correctIndex: 2),
        QuizQuestion(question: 'Which sign means add?', options: ['-', '+', '×', '='], correctIndex: 1),
      ],
    );
    await _lessonsRef.add(lesson.toMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSampleLesson,
        tooltip: 'Add sample lesson',
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(
              child: Text('No lessons yet.\nTap + to add one.',
                  textAlign: TextAlign.center),
            );
          }
          final lessons = docs
              .map((d) => Lesson.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${lesson.order}')),
                  title: Text(lesson.title),
                  subtitle: Text(
                      '${lesson.keyPoints.length} key points · ${lesson.questions.length} questions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LessonDetailScreen(lesson: lesson)),
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