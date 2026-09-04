import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unit.dart';
import '../models/app_user.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';

class CreateLessonScreen extends StatefulWidget {
  final Unit unit;
  final AppUser user;
  final Lesson? existing;
  const CreateLessonScreen({
    super.key,
    required this.unit,
    required this.user,
    this.existing,
  });

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _title = TextEditingController();
  final List<_Block> _blocks = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      for (final blk in e.blocks) {
        _blocks.add(_Block.fromModel(blk));
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void _addSection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add a section',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            _sheetItem('🎬', 'Video', 'video'),
            _sheetItem('✨', 'Key points', 'keypoints'),
            _sheetItem('🃏', 'Revision cards', 'cards'),
            _sheetItem('❓', 'Quiz', 'quiz'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(String emoji, String label, String type) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        setState(() => _blocks.add(_Block.starter(type)));
      },
    );
  }

  void _move(int i, int dir) {
    final j = i + dir;
    if (j < 0 || j >= _blocks.length) return;
    setState(() {
      final tmp = _blocks[i];
      _blocks[i] = _blocks[j];
      _blocks[j] = tmp;
    });
  }

  void _openJsonImport() {
    final ctrl = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Import from JSON'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Paste lesson content as JSON. This replaces the sections below.',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ctrl,
                    maxLines: 10,
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: '{ "title": "...", "blocks": [ ... ] }',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      TextButton.icon(
                        onPressed: () => setLocal(() => ctrl.text = _template),
                        icon: const Icon(Icons.article_outlined, size: 18),
                        label: const Text('Load template'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              const ClipboardData(text: _template));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Template copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy template'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final result = _parseJson(ctrl.text);
                if (result == null) {
                  setLocal(() => error =
                      'Could not read that JSON. Check the format and try again.');
                  return;
                }
                setState(() {
                  for (final b in _blocks) {
                    b.dispose();
                  }
                  _blocks
                    ..clear()
                    ..addAll(result.blocks);
                  if (result.title.isNotEmpty) _title.text = result.title;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Imported ${result.blocks.length} sections ✅')),
                );
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  _ParsedLesson? _parseJson(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final map = Map<String, dynamic>.from(data);
      final title = (map['title'] ?? '').toString();
      final blocks = <_Block>[];

      if (map['blocks'] is List) {
        for (final rawB in (map['blocks'] as List)) {
          final m = Map<String, dynamic>.from(rawB as Map);
          final t = (m['type'] ?? '').toString().toLowerCase();
          if (t == 'video') {
            final b = _Block('video');
            b.video.text = (m['url'] ?? m['videoUrl'] ?? '').toString();
            blocks.add(b);
          } else if (t == 'keypoints' || t == 'points') {
            final b = _Block('keypoints');
            for (final p in (m['points'] ?? m['keyPoints'] ?? [])) {
              b.points.add(TextEditingController(text: p.toString()));
            }
            blocks.add(b);
          } else if (t == 'cards') {
            final b = _Block('cards');
            for (final c in (m['cards'] ?? [])) {
              final cm = Map<String, dynamic>.from(c as Map);
              final cc = _CardCtrl();
              cc.front.text = (cm['front'] ?? '').toString();
              cc.back.text = (cm['back'] ?? '').toString();
              b.cards.add(cc);
            }
            blocks.add(b);
          } else if (t == 'quiz' || t == 'questions') {
            final b = _Block('quiz');
            for (final q in (m['questions'] ?? [])) {
              b.questions.add(_questionFromMap(Map<String, dynamic>.from(q)));
            }
            blocks.add(b);
          }
        }
      } else {
        final vids = map['videos'] ??
            (map['video'] != null ? [map['video']] : const []);
        for (final v in vids) {
          final b = _Block('video');
          b.video.text = v.toString();
          blocks.add(b);
        }
        final kp = map['keyPoints'] ?? map['points'];
        if (kp is List && kp.isNotEmpty) {
          final b = _Block('keypoints');
          for (final p in kp) {
            b.points.add(TextEditingController(text: p.toString()));
          }
          blocks.add(b);
        }
        if (map['cards'] is List && (map['cards'] as List).isNotEmpty) {
          final b = _Block('cards');
          for (final c in (map['cards'] as List)) {
            final cm = Map<String, dynamic>.from(c as Map);
            final cc = _CardCtrl();
            cc.front.text = (cm['front'] ?? '').toString();
            cc.back.text = (cm['back'] ?? '').toString();
            b.cards.add(cc);
          }
          blocks.add(b);
        }
        if (map['questions'] is List &&
            (map['questions'] as List).isNotEmpty) {
          final b = _Block('quiz');
          for (final q in (map['questions'] as List)) {
            b.questions.add(_questionFromMap(Map<String, dynamic>.from(q)));
          }
          blocks.add(b);
        }
      }
      if (blocks.isEmpty && title.isEmpty) return null;
      return _ParsedLesson(title, blocks);
    } catch (_) {
      return null;
    }
  }

  _QuestionCtrl _questionFromMap(Map<String, dynamic> m) {
    final qc = _QuestionCtrl(opts: 0);
    qc.question.text = (m['question'] ?? '').toString();
    final opts = (m['options'] as List?) ?? const [];
    for (final o in opts) {
      qc.options.add(TextEditingController(text: o.toString()));
    }
    while (qc.options.length < 2) {
      qc.options.add(TextEditingController());
    }
    final ci = m['correctIndex'];
    qc.correctIndex = ci is int ? ci : int.tryParse('${ci ?? 0}') ?? 0;
    if (qc.correctIndex < 0 || qc.correctIndex >= qc.options.length) {
      qc.correctIndex = 0;
    }
    return qc;
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lesson title')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final blocks = _blocks.map((b) => b.toModel()).where((b) {
        switch (b.type) {
          case 'video':
            return b.videoUrl.isNotEmpty;
          case 'keypoints':
            return b.points.isNotEmpty;
          case 'cards':
            return b.cards.isNotEmpty;
          case 'quiz':
            return b.questions.isNotEmpty;
          default:
            return false;
        }
      }).toList();

      final lessonsRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.unit.id)
          .collection('lessons');

      int order;
      if (widget.existing != null) {
        order = widget.existing!.order;
      } else {
        final existingDocs = await lessonsRef.get();
        order = existingDocs.docs.length + 1;
      }

      final lesson = Lesson(
        id: '',
        order: order,
        title: _title.text.trim(),
        blocks: blocks,
      );

      if (widget.existing == null) {
        await lessonsRef.add(lesson.toMap());
      } else {
        await lessonsRef.doc(widget.existing!.id).update(lesson.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existing == null
                  ? 'Lesson created ✅'
                  : 'Lesson updated ✅')),
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
        title: Text(isEdit ? 'Edit lesson' : 'New lesson'),
        actions: [
          IconButton(
            tooltip: 'Import from JSON',
            icon: const Icon(Icons.bolt),
            onPressed: _openJsonImport,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSection,
        icon: const Icon(Icons.add),
        label: const Text('Add section'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Lesson title'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openJsonImport,
            icon: const Icon(Icons.bolt),
            label: const Text('Import all content from JSON (one shot)'),
          ),
          const SizedBox(height: 8),
          if (_blocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No sections yet.\nTap "Add section" to build the lesson,\nor import JSON.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ..._blocks.asMap().entries.map((e) => _blockEditor(e.key, e.value)),
          const SizedBox(height: 16),
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
                  : (isEdit ? 'Save changes' : 'Create lesson')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockEditor(int i, _Block b) {
    const labels = {
      'video': '🎬 Video',
      'keypoints': '✨ Key points',
      'cards': '🃏 Revision cards',
      'quiz': '❓ Quiz',
    };
    return Card(
      color: const Color(0xFFFBFDFB),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(labels[b.type] ?? b.type,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: () => _move(i, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 20),
                  onPressed: () => _move(i, 1),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() {
                    _blocks[i].dispose();
                    _blocks.removeAt(i);
                  }),
                ),
              ],
            ),
            _blockBody(b),
          ],
        ),
      ),
    );
  }

  Widget _blockBody(_Block b) {
    switch (b.type) {
      case 'video':
        return TextField(
          controller: b.video,
          decoration: const InputDecoration(
            labelText: 'Video URL',
            hintText: 'YouTube or Vimeo link',
            isDense: true,
          ),
        );
      case 'keypoints':
        return Column(
          children: [
            ...b.points.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: e.value,
                          decoration: InputDecoration(
                              hintText: 'Point ${e.key + 1}', isDense: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => setState(() {
                          b.points[e.key].dispose();
                          b.points.removeAt(e.key);
                        }),
                      ),
                    ],
                  ),
                )),
            _addRow('Add point',
                () => setState(() => b.points.add(TextEditingController()))),
          ],
        );
      case 'cards':
        return Column(
          children: [
            ...b.cards.asMap().entries.map((e) {
              final c = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Card ${e.key + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(() {
                            b.cards[e.key].dispose();
                            b.cards.removeAt(e.key);
                          }),
                        ),
                      ],
                    ),
                    TextField(
                      controller: c.front,
                      decoration: const InputDecoration(
                          labelText: 'Front (question)', isDense: true),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: c.back,
                      decoration: const InputDecoration(
                          labelText: 'Back (answer)', isDense: true),
                    ),
                  ],
                ),
              );
            }),
            _addRow('Add card', () => setState(() => b.cards.add(_CardCtrl()))),
          ],
        );
      case 'quiz':
        return Column(
          children: [
            ...b.questions.asMap().entries.map((e) {
              final q = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6EEE6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Question ${e.key + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(() {
                            b.questions[e.key].dispose();
                            b.questions.removeAt(e.key);
                          }),
                        ),
                      ],
                    ),
                    TextField(
                      controller: q.question,
                      decoration: const InputDecoration(
                          labelText: 'Question', isDense: true),
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap the circle to mark the correct answer:',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ...q.options.asMap().entries.map((o) => Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                q.correctIndex == o.key
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: q.correctIndex == o.key
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => q.correctIndex = o.key),
                            ),
                            Expanded(
                              child: TextField(
                                controller: o.value,
                                decoration: InputDecoration(
                                    hintText: 'Option ${o.key + 1}',
                                    isDense: true),
                              ),
                            ),
                            if (q.options.length > 2)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() {
                                  q.options[o.key].dispose();
                                  q.options.removeAt(o.key);
                                  if (q.correctIndex >= q.options.length) {
                                    q.correctIndex = 0;
                                  }
                                }),
                              ),
                          ],
                        )),
                    if (q.options.length < 6)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(
                              () => q.options.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add option'),
                        ),
                      ),
                  ],
                ),
              );
            }),
            _addRow('Add question',
                () => setState(() => b.questions.add(_QuestionCtrl()))),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _addRow(String label, VoidCallback onTap) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(foregroundColor: AppTheme.seed),
        ),
      );
}

class _Block {
  String type;
  final TextEditingController video = TextEditingController();
  final List<TextEditingController> points = [];
  final List<_CardCtrl> cards = [];
  final List<_QuestionCtrl> questions = [];

  _Block(this.type);

  factory _Block.starter(String type) {
    final b = _Block(type);
    if (type == 'keypoints') b.points.add(TextEditingController());
    if (type == 'cards') b.cards.add(_CardCtrl());
    if (type == 'quiz') b.questions.add(_QuestionCtrl());
    return b;
  }

  factory _Block.fromModel(LessonBlock blk) {
    final b = _Block(blk.type);
    if (blk.type == 'video') b.video.text = blk.videoUrl;
    for (final p in blk.points) {
      b.points.add(TextEditingController(text: p));
    }
    for (final c in blk.cards) {
      final cc = _CardCtrl();
      cc.front.text = c.front;
      cc.back.text = c.back;
      b.cards.add(cc);
    }
    for (final q in blk.questions) {
      final qc = _QuestionCtrl(opts: 0);
      qc.question.text = q.question;
      for (final o in q.options) {
        qc.options.add(TextEditingController(text: o));
      }
      while (qc.options.length < 2) {
        qc.options.add(TextEditingController());
      }
      qc.correctIndex = q.correctIndex;
      if (qc.correctIndex >= qc.options.length) qc.correctIndex = 0;
      b.questions.add(qc);
    }
    return b;
  }

  LessonBlock toModel() {
    switch (type) {
      case 'video':
        return LessonBlock(type: 'video', videoUrl: video.text.trim());
      case 'keypoints':
        return LessonBlock(
          type: 'keypoints',
          points: points
              .map((c) => c.text.trim())
              .where((t) => t.isNotEmpty)
              .toList(),
        );
      case 'cards':
        return LessonBlock(
          type: 'cards',
          cards: cards
              .where((c) => c.front.text.trim().isNotEmpty)
              .map((c) => LessonCard(
                  front: c.front.text.trim(), back: c.back.text.trim()))
              .toList(),
        );
      case 'quiz':
        return LessonBlock(
          type: 'quiz',
          questions: questions
              .where((q) => q.question.text.trim().isNotEmpty)
              .map((q) => q.toModel())
              .toList(),
        );
      default:
        return LessonBlock(type: type);
    }
  }

  void dispose() {
    video.dispose();
    for (final p in points) {
      p.dispose();
    }
    for (final c in cards) {
      c.dispose();
    }
    for (final q in questions) {
      q.dispose();
    }
  }
}

class _CardCtrl {
  final TextEditingController front = TextEditingController();
  final TextEditingController back = TextEditingController();
  void dispose() {
    front.dispose();
    back.dispose();
  }
}

class _QuestionCtrl {
  final TextEditingController question = TextEditingController();
  final List<TextEditingController> options;
  int correctIndex = 0;
  _QuestionCtrl({int opts = 4})
      : options = List.generate(opts, (_) => TextEditingController());

  QuizQuestion toModel() {
    final texts = options.map((o) => o.text.trim()).toList();
    final kept = <int>[];
    for (var i = 0; i < texts.length; i++) {
      if (texts[i].isNotEmpty) kept.add(i);
    }
    final opts = kept.map((i) => texts[i]).toList();
    var correct = kept.indexOf(correctIndex);
    if (correct < 0) correct = 0;
    return QuizQuestion(
        question: question.text.trim(), options: opts, correctIndex: correct);
  }

  void dispose() {
    question.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

class _ParsedLesson {
  final String title;
  final List<_Block> blocks;
  _ParsedLesson(this.title, this.blocks);
}

const String _template = '''{
  "title": "Lesson 1: Addition",
  "blocks": [
    { "type": "video", "url": "https://youtu.be/VIDEO_ID" },
    { "type": "video", "url": "https://youtu.be/SECOND_VIDEO" },
    { "type": "keypoints", "points": [
      "A number tells us how many.",
      "The plus sign (+) means add."
    ]},
    { "type": "cards", "cards": [
      { "front": "2 + 3", "back": "5" },
      { "front": "10 + 5", "back": "15" }
    ]},
    { "type": "quiz", "questions": [
      { "question": "4 + 5 = ?", "options": ["7","8","9","10"], "correctIndex": 2 },
      { "question": "Which sign means add?", "options": ["-","+","x"], "correctIndex": 1 }
    ]}
  ]
}''';
