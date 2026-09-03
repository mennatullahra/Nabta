import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lesson.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final Set<int> _flipped = {};        // which cards show their back
  late final List<int?> _selected;     // chosen answer per question (null = none)

  @override
  void initState() {
    super.initState();
    _selected = List<int?>.filled(widget.lesson.questions.length, null);
  }

  Future<void> _openVideo() async {
    final uri = Uri.parse(widget.lesson.videoUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${widget.lesson.videoUrl}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title('Video'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.play_circle_fill, size: 40, color: Colors.red),
              title: const Text('Watch the lesson video'),
              subtitle: Text(lesson.videoUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: _openVideo,
            ),
          ),

          _title('Key points'),
          ...lesson.keyPoints.map((p) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(p),
              )),

          _title('Revision cards (tap to flip)'),
          ...lesson.cards.asMap().entries.map((e) {
            final i = e.key;
            final card = e.value;
            final showBack = _flipped.contains(i);
            return GestureDetector(
              onTap: () => setState(() {
                showBack ? _flipped.remove(i) : _flipped.add(i);
              }),
              child: Card(
                color: showBack ? Colors.blue.shade50 : Colors.amber.shade50,
                child: Container(
                  height: 90,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  child: Text(showBack ? card.back : card.front,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            );
          }),

          _title('Quiz'),
          ...lesson.questions.asMap().entries.map((e) {
            final qi = e.key;
            final q = e.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q${qi + 1}. ${q.question}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...q.options.asMap().entries.map((o) {
                      final oi = o.key;
                      final chosen = _selected[qi];
                      Color? bg;
                      if (chosen != null) {
                        if (oi == q.correctIndex) bg = Colors.green.shade100;
                        else if (oi == chosen) bg = Colors.red.shade100;
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(o.value),
                          onTap: chosen == null
                              ? () => setState(() => _selected[qi] = oi)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );
}