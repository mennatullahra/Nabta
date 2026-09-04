import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/app_user.dart';
import '../models/course.dart';

class CreateCourseScreen extends StatefulWidget {
  final Subject subject;
  final AppUser user;
  final Course? existing;
  const CreateCourseScreen({
    super.key,
    required this.subject,
    required this.user,
    this.existing,
  });

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _gradeLevel = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description;
      _gradeLevel.text = e.gradeLevel;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _gradeLevel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final course = Course(
        id: widget.existing?.id ?? '',
        subjectId: widget.subject.id,
        teacherId: widget.existing?.teacherId ?? widget.user.uid,
        teacherName: widget.existing?.teacherName ?? widget.user.name,
        title: _title.text.trim(),
        description: _description.text.trim(),
        gradeLevel: _gradeLevel.text.trim(),
        isPremium: widget.existing?.isPremium ?? false,
        price: widget.existing?.price ?? 0,
        lessonCount: widget.existing?.lessonCount ?? 0,
      );

      final coll = FirebaseFirestore.instance.collection('courses');
      if (widget.existing == null) {
        await coll.add(course.toMap());
      } else {
        await coll.doc(widget.existing!.id).update(course.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existing == null
                  ? 'Course created ✅'
                  : 'Course updated ✅')),
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
        title: Text(
            isEdit ? 'Edit course' : 'New course in ${widget.subject.name}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Course title'),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeLevel,
              decoration: const InputDecoration(
                labelText: 'Grade level',
                hintText: 'e.g. Grade 4',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a grade'
                  : null,
            ),
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
                    : (isEdit ? 'Save changes' : 'Create course')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
