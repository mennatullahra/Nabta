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
  QuizQuestion(
      {required this.question,
      required this.options,
      required this.correctIndex});

  Map<String, dynamic> toMap() =>
      {'question': question, 'options': options, 'correctIndex': correctIndex};
  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        question: m['question'] ?? '',
        options: List<String>.from(m['options'] ?? []),
        correctIndex: m['correctIndex'] ?? 0,
      );
}

class Lesson {
  final String id;
  final int order;
  final String title;
  final String videoUrl;
  final List<String> keyPoints;
  final List<LessonCard> cards;
  final List<QuizQuestion> questions;

  Lesson({
    required this.id,
    required this.order,
    required this.title,
    required this.videoUrl,
    required this.keyPoints,
    required this.cards,
    required this.questions,
  });

  Map<String, dynamic> toMap() => {
        'order': order,
        'title': title,
        'videoUrl': videoUrl,
        'keyPoints': keyPoints,
        'cards': cards.map((c) => c.toMap()).toList(),
        'questions': questions.map((q) => q.toMap()).toList(),
      };

  factory Lesson.fromMap(String id, Map<String, dynamic> map) => Lesson(
        id: id,
        order: map['order'] ?? 0,
        title: map['title'] ?? '',
        videoUrl: map['videoUrl'] ?? '',
        keyPoints: List<String>.from(map['keyPoints'] ?? []),
        cards: (map['cards'] as List<dynamic>? ?? [])
            .map((c) => LessonCard.fromMap(c as Map<String, dynamic>))
            .toList(),
        questions: (map['questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
            .toList(),
      );
}