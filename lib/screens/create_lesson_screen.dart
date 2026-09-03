import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/app_user.dart';
import '../models/lesson.dart';

class CreateLessonScreen extends StatefulWidget {
  final Course course;
  final AppUser user;
  final Lesson? existing;
  const CreateLessonScreen({
    super.key,
    required this.course,
    required this.user,
    this.existing,
  });

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _videoUrl = TextEditingController();

  // The three growing lists — each item is a controller (or group of them).
  final List<TextEditingController> _keyPoints = [];
  final List<_CardCtrl> _cards = [];
  final List<_QuestionCtrl> _questions = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _videoUrl.text = e.videoUrl;
      for (final p in e.keyPoints) {
        _keyPoints.add(TextEditingController(text: p));
      }
      for (final card in e.cards) {
        final cc = _CardCtrl();
        cc.front.text = card.front;
        cc.back.text = card.back;
        _cards.add(cc);
      }
      for (final q in e.questions) {
        final qc = _QuestionCtrl();
        qc.question.text = q.question;
        for (var i = 0; i < q.options.length && i < 4; i++) {
          qc.options[i].text = q.options[i];
        }
        qc.correctIndex = q.correctIndex;
        _questions.add(qc);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _videoUrl.dispose();
    for (final c in _keyPoints) c.dispose();
    for (final c in _cards) c.dispose();
    for (final q in _questions) q.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // Collect the lists, skipping empty rows.
      final keyPoints = _keyPoints
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final cards = _cards
          .where((c) => c.front.text.trim().isNotEmpty)
          .map((c) => LessonCard(
              front: c.front.text.trim(), back: c.back.text.trim()))
          .toList();

      final questions = _questions
          .where((q) => q.question.text.trim().isNotEmpty)
          .map((q) => QuizQuestion(
                question: q.question.text.trim(),
                options: q.options.map((o) => o.text.trim()).toList(),
                correctIndex: q.correctIndex,
              ))
          .toList();

      final lessonsRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .collection('lessons');

      int order;
      if (widget.existing != null) {
        order = widget.existing!.order;         // keep its place
      } else {
        final existingDocs = await lessonsRef.get();
        order = existingDocs.docs.length + 1;
      }

      final lesson = Lesson(
        id: '',
        order: order,
        title: _title.text.trim(),
        videoUrl: _videoUrl.text.trim(),
        keyPoints: keyPoints,
        cards: cards,
        questions: questions,
      );

      if (widget.existing == null) {
        await lessonsRef.add(lesson.toMap());
      } else {
        await lessonsRef.doc(widget.existing!.id).update(lesson.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              widget.existing == null ? 'Lesson created ✅' : 'Lesson updated ✅')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New lesson' : 'Edit lesson'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Basics ---
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Lesson title', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _videoUrl,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                hintText: 'YouTube or Vimeo link',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please add a video link' : null,
            ),

            // --- Key points ---
            _sectionHeader('Key points'),
            ..._keyPoints.asMap().entries.map((e) {
              final i = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(
                          hintText: 'Point ${i + 1}',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => setState(() {
                        _keyPoints[i].dispose();
                        _keyPoints.removeAt(i);
                      }),
                    ),
                  ],
                ),
              );
            }),
            _addButton('Add key point', () {
              setState(() => _keyPoints.add(TextEditingController()));
            }),

            // --- Revision cards ---
            _sectionHeader('Revision cards'),
            ..._cards.asMap().entries.map((e) {
              final i = e.key;
              final card = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Card ${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () => setState(() {
                              _cards[i].dispose();
                              _cards.removeAt(i);
                            }),
                          ),
                        ],
                      ),
                      TextField(
                        controller: card.front,
                        decoration: const InputDecoration(
                            labelText: 'Front (question)', isDense: true),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: card.back,
                        decoration: const InputDecoration(
                            labelText: 'Back (answer)', isDense: true),
                      ),
                    ],
                  ),
                ),
              );
            }),
            _addButton('Add card', () {
              setState(() => _cards.add(_CardCtrl()));
            }),

            // --- Quiz questions ---
            _sectionHeader('Quiz questions'),
            ..._questions.asMap().entries.map((e) {
              final qi = e.key;
              final q = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Question ${qi + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () => setState(() {
                              _questions[qi].dispose();
                              _questions.removeAt(qi);
                            }),
                          ),
                        ],
                      ),
                      TextField(
                        controller: q.question,
                        decoration: const InputDecoration(
                            labelText: 'Question', isDense: true),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap the circle to mark the correct answer:',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ...List.generate(4, (oi) {
                        return Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                q.correctIndex == oi
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: q.correctIndex == oi
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => q.correctIndex = oi),
                            ),
                            Expanded(
                              child: TextField(
                                controller: q.options[oi],
                                decoration: InputDecoration(
                                    hintText: 'Option ${oi + 1}', isDense: true),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
            _addButton('Add question', () {
              setState(() => _questions.add(_QuestionCtrl()));
            }),

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_saving
                  ? 'Saving...'
                  : (widget.existing == null ? 'Create lesson' : 'Save changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _addButton(String label, VoidCallback onTap) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add),
          label: Text(label),
        ),
      );
}

// Holds the two controllers for one revision card.
class _CardCtrl {
  final TextEditingController front = TextEditingController();
  final TextEditingController back = TextEditingController();
  void dispose() {
    front.dispose();
    back.dispose();
  }
}

// Holds the controllers + correct answer for one quiz question.
class _QuestionCtrl {
  final TextEditingController question = TextEditingController();
  final List<TextEditingController> options =
      List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;
  void dispose() {
    question.dispose();
    for (final o in options) o.dispose();
  }
}