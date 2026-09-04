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
  final Set<String> _flipped = {}; // 'bi:ci'
  final Map<String, int> _selected = {}; // 'bi:qi' -> option index
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
    if (!widget.user.isTeacher) _loadCompletion();
  }

  Future<void> _loadCompletion() async {
    final doc = await _progressRef.get();
    if (mounted) setState(() => _completed = doc.exists);
  }

  void _pick(String key, int oi, int correct) {
    setState(() => _selected[key] = oi);
    if (oi == correct) {
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
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

  Future<void> _openVideo(String raw) async {
    final url = raw.trim();
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final children = <Widget>[];
    var videoNum = 0;

    for (var bi = 0; bi < lesson.blocks.length; bi++) {
      final b = lesson.blocks[bi];
      switch (b.type) {
        case 'video':
          videoNum++;
          children.add(_videoPanel(b, videoNum, lesson.videoCount));
          break;
        case 'keypoints':
          if (b.points.isNotEmpty) children.add(_keyPointsPanel(b));
          break;
        case 'cards':
          if (b.cards.isNotEmpty) children.addAll(_cardsSection(bi, b));
          break;
        case 'quiz':
          if (b.questions.isNotEmpty) children.addAll(_quizSection(bi, b));
          break;
      }
    }

    if (!widget.user.isTeacher) {
      children.add(const SizedBox(height: 18));
      children.add(SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _toggleComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: _completed ? AppTheme.seed : AppTheme.sun,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: Icon(
              _completed ? Icons.check_circle : Icons.emoji_events_rounded),
          label: Text(_completed ? 'Completed 🌟' : 'Mark as complete'),
        ),
      ));
    }

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
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _videoPanel(LessonBlock b, int num, int total) {
    final label = b.title.isNotEmpty
        ? b.title
        : (total > 1 ? 'Watch — video $num' : 'Watch');
    return _panel(Row(
      children: [
        const AppImage('sun.png', width: 60, placeholderEmoji: '🌞'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _openVideo(b.videoUrl),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.coral),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Watch now'),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _keyPointsPanel(LessonBlock b) {
    return _panel(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.title.isNotEmpty ? b.title : '✨ Key points',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        ...b.points.map((p) => Padding(
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
    ));
  }

  List<Widget> _cardsSection(int bi, LessonBlock b) {
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(b.title.isNotEmpty ? b.title : '🃏 Tap the cards to flip!',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF23405C))),
      ),
    ];
    for (var ci = 0; ci < b.cards.length; ci++) {
      final card = b.cards[ci];
      final key = '$bi:$ci';
      final showBack = _flipped.contains(key);
      widgets.add(GestureDetector(
        onTap: () => setState(() {
          if (showBack) {
            _flipped.remove(key);
          } else {
            _flipped.add(key);
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
      ));
    }
    return widgets;
  }

  List<Widget> _quizSection(int bi, LessonBlock b) {
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Row(
          children: [
            const AppImage('cat.png', width: 54, placeholderEmoji: '🐱'),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title.isNotEmpty ? b.title : 'Practice',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF23405C))),
                const Text('Answer the questions',
                    style: TextStyle(color: Color(0xFF4A6478), fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    ];
    for (var qi = 0; qi < b.questions.length; qi++) {
      final q = b.questions[qi];
      final key = '$bi:$qi';
      final chosen = _selected[key];
      widgets.add(Container(
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
            Text('Q${qi + 1}.  ${q.question}',
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
              children: q.options.asMap().entries.map((o) {
                final oi = o.key;
                Color bg = const Color(0xFFF1F6FB);
                Color border = const Color(0xFFDDE8F2);
                Color txt = const Color(0xFF23405C);
                if (chosen != null) {
                  if (oi == q.correctIndex) {
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
                  onTap: chosen == null
                      ? () => _pick(key, oi, q.correctIndex)
                      : null,
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
                chosen == q.correctIndex
                    ? 'Correct! 🎉'
                    : 'Good try! The green one is right. 💪',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: chosen == q.correctIndex
                      ? const Color(0xFF1E7A4D)
                      : const Color(0xFFB3402F),
                ),
              ),
            ],
          ],
        ),
      ));
    }
    return widgets;
  }

  Widget _panel(Widget child) {
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
