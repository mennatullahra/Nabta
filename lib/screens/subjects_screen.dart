import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import 'courses_screen.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class SubjectsScreen extends StatelessWidget {
  final AppUser user;
  const SubjectsScreen({super.key, required this.user});

  // Maps our stored color names to real Flutter colors.
  Color _colorFor(String name) {
    switch (name) {
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'amber': return Colors.amber.shade800;
      case 'coral': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The query: all subjects, sorted by their 'order' field.
    final subjectsQuery =
        FirebaseFirestore.instance.collection('subjects').orderBy('order');

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.name.split(' ').first} 👋'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (user.isTeacher)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(child: Chip(label: Text('Teacher'))),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: subjectsQuery.snapshots(),
        builder: (context, snapshot) {
          // 1. Still loading?
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Something went wrong?
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // 3. Got data — turn documents into Subject objects.
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No subjects yet.'));
          }
          final subjects = docs
              .map((doc) =>
                  Subject.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          // 4. Show them as a 2-column grid.
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final color = _colorFor(subject.iconColor);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CoursesScreen(subject: subject, user: user),),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 40, color: color),
                      const SizedBox(height: 12),
                      Text(subject.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subject.nameAr, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}