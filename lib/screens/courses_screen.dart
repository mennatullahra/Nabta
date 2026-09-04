import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/course.dart';
import '../models/app_user.dart';
import '../utils/kid_helpers.dart';
import 'lessons_screen.dart';
import 'create_course_screen.dart';

class CoursesScreen extends StatefulWidget {
  final Subject subject;
  final AppUser user;
  const CoursesScreen({super.key, required this.subject, required this.user});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _search = '';

  Subject get subject => widget.subject;
  AppUser get user => widget.user;

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
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesQuery = FirebaseFirestore.instance
        .collection('courses')
        .where('subjectId', isEqualTo: subject.id);

    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      floatingActionButton: user.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateCourseScreen(subject: subject, user: user),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New course'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: coursesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var courses = (snapshot.data?.docs ?? [])
                    .map((doc) => Course.fromMap(
                        doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                if (_search.isNotEmpty) {
                  courses = courses
                      .where((c) =>
                          c.title.toLowerCase().contains(_search) ||
                          c.teacherName.toLowerCase().contains(_search))
                      .toList();
                }

                if (courses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_search.isNotEmpty ? '🔍' : '🌱',
                            style: const TextStyle(fontSize: 52)),
                        const SizedBox(height: 10),
                        Text(
                          _search.isNotEmpty
                              ? 'No courses match "$_search"'
                              : (user.isTeacher
                                  ? 'No courses yet.\nTap + to add your first one.'
                                  : 'No courses here yet.\nCheck back soon!'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return _CourseCard(
                      course: course,
                      accent: subjectColor(subject.iconColor),
                      user: user,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LessonsScreen(course: course, user: user),
                        ),
                      ),
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateCourseScreen(
                              subject: subject,
                              user: user,
                              existing: course),
                        ),
                      ),
                      onDelete: () => _confirmDeleteCourse(context, course),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Color accent;
  final AppUser user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.accent,
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.play_lesson_rounded,
                    color: accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${course.teacherName} · ${course.gradeLevel}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: course.isPremium
                            ? const Color(0xFFFFF1D6)
                            : const Color(0xFFDCF3E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.isPremium ? '⭐ Premium' : '✓ Free',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: course.isPremium
                              ? const Color(0xFF9A6B00)
                              : const Color(0xFF1E7A4D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (user.isTeacher)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                )
              else
                const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
