import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/kid_helpers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';
import 'units_screen.dart';
import 'progress_screen.dart';
import 'create_subject_screen.dart';

class SubjectsScreen extends StatelessWidget {
  final AppUser user;
  const SubjectsScreen({super.key, required this.user});

  /// Deletes a subject and everything under it (its units and their lessons),
  /// so nothing is left orphaned. Safe for a small curriculum.
  Future<void> _deleteSubject(BuildContext context, Subject subject) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
            'This removes "${subject.name}" AND all its units and lessons. '
            'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final db = FirebaseFirestore.instance;
      // Units are stored in the 'courses' collection.
      final units = await db
          .collection('courses')
          .where('subjectId', isEqualTo: subject.id)
          .get();

      for (final unitDoc in units.docs) {
        final lessons = await unitDoc.reference.collection('lessons').get();
        const chunk = 400; // batch limit is 500
        for (var i = 0; i < lessons.docs.length; i += chunk) {
          final batch = db.batch();
          for (final d in lessons.docs.skip(i).take(chunk)) {
            batch.delete(d.reference);
          }
          await batch.commit();
        }
        await unitDoc.reference.delete();
      }
      await db.collection('subjects').doc(subject.id).delete();

      messenger.showSnackBar(const SnackBar(content: Text('Subject deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsQuery =
        FirebaseFirestore.instance.collection('subjects').orderBy('order');
    final firstName =
        user.name.trim().isEmpty ? 'friend' : user.name.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF3FAFF),
      floatingActionButton: user.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSubjectScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New subject'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: StreamBuilder<QuerySnapshot>(
          stream: subjectsQuery.snapshots(),
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            var subjects = (snapshot.data?.docs ?? [])
                .map((doc) => Subject.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>))
                .toList();

            // Students see only their grade's subjects.
            // (Subjects with no grade set are shown to everyone.)
            if (!user.isTeacher && user.grade.isNotEmpty) {
              subjects = subjects
                  .where((s) => s.grade.isEmpty || s.grade == user.grade)
                  .toList();
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('Hi, $firstName!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
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
                          icon:
                              const Icon(Icons.logout, color: Colors.black45),
                          tooltip: 'Log out',
                          onPressed: () => AuthService().signOut(),
                        ),
                      ],
                    ),
                  ),
                ),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Let's learn today!",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(
                                    user.isTeacher
                                        ? 'Manage your subjects and units 🎈'
                                        : (user.grade.isEmpty
                                            ? 'Pick a subject to start 🎈'
                                            : '${user.grade} · pick a subject 🎈'),
                                    style: const TextStyle(
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
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'No subjects for your grade yet.\nCheck back soon!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54)),
                      ),
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
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = subjects[index];
                          return _SubjectTile(
                            subject: subject,
                            showGrade: user.isTeacher,
                            isTeacher: user.isTeacher,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UnitsScreen(
                                    subject: subject, user: user),
                              ),
                            ),
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateSubjectScreen(existing: subject),
                              ),
                            ),
                            onDelete: () => _deleteSubject(context, subject),
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
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final bool showGrade;
  final bool isTeacher;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _SubjectTile({
    required this.subject,
    required this.onTap,
    this.showGrade = false,
    this.isTeacher = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = subjectColor(subject.iconColor);
    final tile = Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(subjectEmoji(subject.name),
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 8),
              Text(subject.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(subject.nameAr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              if (showGrade)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      subject.grade.isEmpty ? 'All grades' : subject.grade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.8))),
                ),
            ],
          ),
        ),
      ),
    );

    if (!isTeacher) return tile;

    // Teachers get an edit/delete menu in the corner.
    return Stack(
      fit: StackFit.expand,
      children: [
        tile,
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: color, size: 20),
              tooltip: 'Edit subject',
              onSelected: (v) {
                if (v == 'edit') onEdit?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}