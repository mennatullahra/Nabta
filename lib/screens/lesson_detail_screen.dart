import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../utils/kid_helpers.dart';
import '../services/sound_service.dart';
import '../widgets/kid_background.dart';
import '../widgets/app_image.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final AppUser user;
  const LessonDetailScreen(
      {super.key, required this.lesson, required this.user});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final Set<int> _flipped = {};
  late final List<int?> _selected;
  bool _completed = false;

  DocumentReference<Map<String, dynamic>> get _progressRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('completedLessons')
          .doc(widget.lesson.id);

  @override
  void initState() {
    super.initState();
    _selected = List<int?>.filled(widget.lesson.questions.length, null);
    if (!widget.user.isTeacher) _loadCompletion();
  }

  Future<void> _loadCompletion() async {
    final doc = await _progressRef.get();
    if (mounted) setState(() => _completed = doc.exists);
  }

  void _pickAnswer(int qi, int oi) {
    setState(() => _selected[qi] = oi);
    if (oi == widget.lesson.questions[qi].correctIndex) {
      SoundService.correct();
    } else {
      SoundService.wrong();
    }
  }

  Future<void> _toggleComplete() async {
    final wasDone = _completed;
    setState(() => _completed = !wasDone);
    if (wasDone) {
      await _progressRef.delete();
    } else {
      await _progressRef.set({
        'completedAt': FieldValue.serverTimestamp(),
        'lessonTitle': widget.lesson.title,
      });
      SoundService.complete();
      if (mounted) _celebrate();
    }
  }

  void _celebrate() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppImage('star.png',
                width: 120, ring: true, placeholderEmoji: '⭐'),
            const SizedBox(height: 12),
            const Text('Well done!',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(praise(widget.lesson.order),
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yay!')),
          ),
        ],
      ),
    );
  }

  Future<void> _openVideo() async {
    final raw = widget.lesson.videoUrl.trim();
    if (raw.isEmpty) return;
    final uri = Uri.parse(raw);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open $raw')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF23405C),
        title: Text(lesson.title,
            style: const TextStyle(
                color: Color(0xFF23405C), fontWeight: FontWeight.w800)),
      ),
      body: KidBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // ---- WATCH panel with sun mascot ----
              _Panel(
                child: Row(
                  children: [
                    const AppImage('sun.png',
                        width: 64, placeholderEmoji: '🌞'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Watch',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 2),
                          const Text('Play the lesson video',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _openVideo,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.coral),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Watch now'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (lesson.keyPoints.isNotEmpty)
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨ Key points',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...lesson.keyPoints.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2, right: 8),
                                  child: Icon(Icons.check_circle,
                                      color: AppTheme.seed, size: 20),
                                ),
                                Expanded(child: Text(p)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

              if (lesson.cards.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Text('🃏 Tap the cards to flip them!',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF23405C))),
                ),
                ...lesson.cards.asMap().entries.map((e) {
                  final i = e.key;
                  final card = e.value;
                  final showBack = _flipped.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (showBack) {
                        _flipped.remove(i);
                      } else {
                        _flipped.add(i);
                      }
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 100,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: showBack
                            ? const Color(0xFFDCEBFF)
                            : const Color(0xFFFFF0CF),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(showBack ? 'Answer' : 'Question',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: showBack
                                      ? const Color(0xFF2A6BB0)
                                      : const Color(0xFF9A6B00))),
                          const SizedBox(height: 6),
                          Text(showBack ? card.back : card.front,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              if (lesson.questions.isNotEmpty) ...[
                // ---- PRACTICE header with cat mascot ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Row(
                    children: [
                      const AppImage('cat.png',
                          width: 54, placeholderEmoji: '🐱'),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Practice',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Color(0xFF23405C))),
                          Text('Answer the questions',
                              style: TextStyle(
                                  color: Color(0xFF4A6478), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                ...lesson.questions.asMap().entries.map((e) {
                  final qi = e.key;
                  final q = e.value;
                  return _QuizCard(
                    index: qi,
                    question: q,
                    chosen: _selected[qi],
                    onPick: (oi) => _pickAnswer(qi, oi),
                  );
                }),
              ],

              if (!widget.user.isTeacher) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _completed ? AppTheme.seed : AppTheme.sun,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: Icon(_completed
                        ? Icons.check_circle
                        : Icons.emoji_events_rounded),
                    label: Text(
                        _completed ? 'Completed 🌟' : 'Mark as complete'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _QuizCard extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final int? chosen;
  final ValueChanged<int> onPick;

  const _QuizCard({
    required this.index,
    required this.question,
    required this.chosen,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q${index + 1}.  ${question.question}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: question.options.asMap().entries.map((o) {
              final oi = o.key;
              Color bg = const Color(0xFFF1F6FB);
              Color border = const Color(0xFFDDE8F2);
              Color txt = const Color(0xFF23405C);
              if (chosen != null) {
                if (oi == question.correctIndex) {
                  bg = const Color(0xFFDCF3E6);
                  border = AppTheme.seed;
                  txt = const Color(0xFF1E7A4D);
                } else if (oi == chosen) {
                  bg = const Color(0xFFFDE2E0);
                  border = AppTheme.coral;
                  txt = const Color(0xFFB3402F);
                }
              }
              return GestureDetector(
                onTap: chosen == null ? () => onPick(oi) : null,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border, width: 2),
                  ),
                  child: Text(o.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: txt)),
                ),
              );
            }).toList(),
          ),
          if (chosen != null) ...[
            const SizedBox(height: 10),
            Text(
              chosen == question.correctIndex
                  ? 'Correct! 🎉'
                  : 'Good try! The green one is right. 💪',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: chosen == question.correctIndex
                    ? const Color(0xFF1E7A4D)
                    : const Color(0xFFB3402F),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
