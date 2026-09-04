class LessonCard {
  final String front;
  final String back;
  LessonCard({required this.front, required this.back});

  Map<String, dynamic> toMap() => {'front': front, 'back': back};
  factory LessonCard.fromMap(Map<String, dynamic> m) =>
      LessonCard(front: m['front'] ?? '', back: m['back'] ?? '');
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  Map<String, dynamic> toMap() =>
      {'question': question, 'options': options, 'correctIndex': correctIndex};
  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        question: m['question'] ?? '',
        options: List<String>.from(m['options'] ?? []),
        correctIndex: (m['correctIndex'] is int)
            ? m['correctIndex']
            : int.tryParse('${m['correctIndex']}') ?? 0,
      );
}

/// One section of a lesson. type: 'video' | 'keypoints' | 'cards' | 'quiz'
class LessonBlock {
  final String type;
  final String title;
  final String videoUrl;
  final List<String> points;
  final List<LessonCard> cards;
  final List<QuizQuestion> questions;

  LessonBlock({
    required this.type,
    this.title = '',
    this.videoUrl = '',
    this.points = const [],
    this.cards = const [],
    this.questions = const [],
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'videoUrl': videoUrl,
        'points': points,
        'cards': cards.map((c) => c.toMap()).toList(),
        'questions': questions.map((q) => q.toMap()).toList(),
      };

  factory LessonBlock.fromMap(Map<String, dynamic> m) => LessonBlock(
        type: (m['type'] ?? 'keypoints').toString(),
        title: (m['title'] ?? '').toString(),
        videoUrl: (m['videoUrl'] ?? m['url'] ?? '').toString(),
        points: List<String>.from(m['points'] ?? m['keyPoints'] ?? []),
        cards: (m['cards'] as List<dynamic>? ?? [])
            .map((c) => LessonCard.fromMap(Map<String, dynamic>.from(c as Map)))
            .toList(),
        questions: (m['questions'] as List<dynamic>? ?? [])
            .map((q) =>
                QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
            .toList(),
      );
}

class Lesson {
  final String id;
  final int order;
  final String title;
  final List<LessonBlock> blocks;

  Lesson({
    required this.id,
    required this.order,
    required this.title,
    required this.blocks,
  });

  int get videoCount => blocks.where((b) => b.type == 'video').length;
  int get keyPointCount => blocks
      .where((b) => b.type == 'keypoints')
      .fold(0, (s, b) => s + b.points.length);
  int get questionCount => blocks
      .where((b) => b.type == 'quiz')
      .fold(0, (s, b) => s + b.questions.length);

  Map<String, dynamic> toMap() {
    final videos =
        blocks.where((b) => b.type == 'video').map((b) => b.videoUrl).toList();
    final keyPoints = <String>[];
    final cards = <LessonCard>[];
    final questions = <QuizQuestion>[];
    for (final b in blocks) {
      if (b.type == 'keypoints') keyPoints.addAll(b.points);
      if (b.type == 'cards') cards.addAll(b.cards);
      if (b.type == 'quiz') questions.addAll(b.questions);
    }
    return {
      'order': order,
      'title': title,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'videoUrl': videos.isNotEmpty ? videos.first : '',
      'keyPoints': keyPoints,
      'cards': cards.map((c) => c.toMap()).toList(),
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory Lesson.fromMap(String id, Map<String, dynamic> map) {
    List<LessonBlock> blocks;
    if (map['blocks'] is List) {
      blocks = (map['blocks'] as List)
          .map((b) => LessonBlock.fromMap(Map<String, dynamic>.from(b as Map)))
          .toList();
    } else {
      blocks = [];
      final v = (map['videoUrl'] ?? '').toString();
      if (v.isNotEmpty) blocks.add(LessonBlock(type: 'video', videoUrl: v));
      final kp = List<String>.from(map['keyPoints'] ?? []);
      if (kp.isNotEmpty) blocks.add(LessonBlock(type: 'keypoints', points: kp));
      final cds = (map['cards'] as List<dynamic>? ?? [])
          .map((c) => LessonCard.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList();
      if (cds.isNotEmpty) blocks.add(LessonBlock(type: 'cards', cards: cds));
      final qs = (map['questions'] as List<dynamic>? ?? [])
          .map((q) =>
              QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList();
      if (qs.isNotEmpty) blocks.add(LessonBlock(type: 'quiz', questions: qs));
    }
    return Lesson(
      id: id,
      order: map['order'] ?? 0,
      title: (map['title'] ?? '').toString(),
      blocks: blocks,
    );
  }
}
