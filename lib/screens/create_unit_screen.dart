import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/app_user.dart';
import '../models/unit.dart';

class CreateUnitScreen extends StatefulWidget {
  final Subject subject;
  final AppUser user;
  final Unit? existing;
  const CreateUnitScreen({
    super.key,
    required this.subject,
    required this.user,
    this.existing,
  });

  @override
  State<CreateUnitScreen> createState() => _CreateUnitScreenState();
}

class _CreateUnitScreenState extends State<CreateUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // Unit inherits its grade from the subject.
      final unit = Unit(
        id: widget.existing?.id ?? '',
        subjectId: widget.subject.id,
        teacherId: widget.existing?.teacherId ?? widget.user.uid,
        teacherName: widget.existing?.teacherName ?? widget.user.name,
        title: _title.text.trim(),
        description: _description.text.trim(),
        gradeLevel: widget.subject.grade,
        isPremium: widget.existing?.isPremium ?? false,
        price: widget.existing?.price ?? 0,
        lessonCount: widget.existing?.lessonCount ?? 0,
      );

      final coll = FirebaseFirestore.instance.collection('courses');
      if (widget.existing == null) {
        await coll.add(unit.toMap());
      } else {
        await coll.doc(widget.existing!.id).update(unit.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existing == null
                  ? 'Unit created ✅'
                  : 'Unit updated ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEdit ? 'Edit unit' : 'New unit in ${widget.subject.name}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Unit title'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please add a description'
                  : null,
            ),
            if (widget.subject.grade.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Grade: ${widget.subject.grade} (from the subject)',
                  style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 26),
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
                    : (isEdit ? 'Save changes' : 'Create unit')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
