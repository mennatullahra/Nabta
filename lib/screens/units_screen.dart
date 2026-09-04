import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/unit.dart';
import '../models/app_user.dart';
import '../utils/kid_helpers.dart';
import 'lessons_screen.dart';
import 'create_unit_screen.dart';

class UnitsScreen extends StatefulWidget {
  final Subject subject;
  final AppUser user;
  const UnitsScreen({super.key, required this.subject, required this.user});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  String _search = '';

  Subject get subject => widget.subject;
  AppUser get user => widget.user;

  Future<void> _confirmDelete(BuildContext context, Unit unit) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete unit?'),
        content: Text('"${unit.title}" will be removed.'),
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
      // Firestore has no cascade delete, so remove the unit's lessons first,
      // otherwise they'd be orphaned (invisible but still stored/billed).
      // Units are stored in the 'courses' collection (kept for compatibility).
      final db = FirebaseFirestore.instance;
      final unitRef = db.collection('courses').doc(unit.id);
      final lessons = await unitRef.collection('lessons').get();

      const chunk = 400; // stay under the 500-op batch limit
      for (var i = 0; i < lessons.docs.length; i += chunk) {
        final batch = db.batch();
        for (final d in lessons.docs.skip(i).take(chunk)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
      await unitRef.delete();

      messenger.showSnackBar(const SnackBar(content: Text('Unit deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitsQuery = FirebaseFirestore.instance
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
                      CreateUnitScreen(subject: subject, user: user),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New unit'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search units...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: unitsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var units = (snapshot.data?.docs ?? [])
                    .map((doc) => Unit.fromMap(
                        doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                if (_search.isNotEmpty) {
                  units = units
                      .where((u) =>
                          u.title.toLowerCase().contains(_search) ||
                          u.teacherName.toLowerCase().contains(_search))
                      .toList();
                }

                if (units.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_search.isNotEmpty ? '🔍' : '🌱',
                            style: const TextStyle(fontSize: 52)),
                        const SizedBox(height: 10),
                        Text(
                          _search.isNotEmpty
                              ? 'No units match "$_search"'
                              : (user.isTeacher
                                  ? 'No units yet.\nTap + to add your first one.'
                                  : 'No units here yet.\nCheck back soon!'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return _UnitCard(
                      unit: unit,
                      accent: subjectColor(subject.iconColor),
                      user: user,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LessonsScreen(unit: unit, user: user),
                        ),
                      ),
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateUnitScreen(
                              subject: subject, user: user, existing: unit),
                        ),
                      ),
                      onDelete: () => _confirmDelete(context, unit),
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

class _UnitCard extends StatelessWidget {
  final Unit unit;
  final Color accent;
  final AppUser user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitCard({
    required this.unit,
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
                child: Icon(Icons.folder_rounded, color: accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                        '${unit.teacherName}${unit.gradeLevel.isNotEmpty ? ' · ${unit.gradeLevel}' : ''}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: unit.isPremium
                            ? const Color(0xFFFFF1D6)
                            : const Color(0xFFDCF3E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unit.isPremium ? '⭐ Premium' : '✓ Free',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: unit.isPremium
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
