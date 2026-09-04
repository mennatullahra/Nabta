import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../utils/kid_helpers.dart';

const String _allGrades = 'All grades';

class CreateSubjectScreen extends StatefulWidget {
  final Subject? existing;
  const CreateSubjectScreen({super.key, this.existing});

  @override
  State<CreateSubjectScreen> createState() => _CreateSubjectScreenState();
}

class _CreateSubjectScreenState extends State<CreateSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameAr = TextEditingController();
  String _grade = 'Grade 4';
  String _color = kSubjectColorKeys.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _nameAr.text = e.nameAr;
      _grade = e.grade.isEmpty ? _allGrades : e.grade;
      _color = e.iconColor.isEmpty ? kSubjectColorKeys.first : e.iconColor;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final coll = FirebaseFirestore.instance.collection('subjects');

      // Work out the sort order.
      int order;
      if (widget.existing != null) {
        order = widget.existing!.order;
      } else {
        final all = await coll.get();
        var maxOrder = 0;
        for (final d in all.docs) {
          final o = (d.data()['order'] ?? 0);
          final v = o is int ? o : int.tryParse('$o') ?? 0;
          if (v > maxOrder) maxOrder = v;
        }
        order = maxOrder + 1;
      }

      final subject = Subject(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        nameAr: _nameAr.text.trim(),
        iconColor: _color,
        order: order,
        grade: _grade == _allGrades ? '' : _grade,
      );

      if (widget.existing == null) {
        await coll.add(subject.toMap());
      } else {
        await coll.doc(widget.existing!.id).update(subject.toMap());
      }

      navigator.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(
              widget.existing == null ? 'Subject added ✅' : 'Subject updated ✅')));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final gradeItems = [_allGrades, ...kGrades];
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit subject' : 'New subject')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Subject name (English)',
                hintText: 'e.g. Math',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameAr,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'Subject name (Arabic)',
                hintText: 'مثال: الرياضيات',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter the Arabic name'
                  : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _grade,
              decoration: const InputDecoration(
                labelText: 'Grade',
                helperText: '"All grades" shows this subject to every student',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: gradeItems
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _grade = v ?? 'Grade 4'),
            ),
            const SizedBox(height: 24),
            const Text('Tile color',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: kSubjectColorKeys.map((key) {
                final c = subjectColor(key);
                final selected = _color == key;
                return GestureDetector(
                  onTap: () => setState(() => _color = key),
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black87 : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Live preview of the tile.
            Center(
              child: _PreviewTile(
                name: _name.text.trim().isEmpty ? 'Subject' : _name.text.trim(),
                nameAr: _nameAr.text.trim(),
                color: _color,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_saving
                    ? 'Saving...'
                    : (isEdit ? 'Save changes' : 'Add subject')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final String name;
  final String nameAr;
  final String color;
  const _PreviewTile(
      {required this.name, required this.nameAr, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = subjectColor(color);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.25), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(subjectEmoji(name),
                  style: const TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(height: 10),
          Text(name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: c)),
          if (nameAr.isNotEmpty)
            Text(nameAr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
