import 'dart:convert';

class Question {
  final String prompt;
  final List<String> options; // exactly 3
  final int correctIndex; // 0..2

  Question({required this.prompt, required this.options, required this.correctIndex})
      : assert(options.length == 3),
        assert(correctIndex >= 0 && correctIndex < 3);

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      prompt: json['question'] as String,
      options: (json['options'] as List).map((e) => e.toString()).toList(),
      correctIndex: (json['correctIndex'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'question': prompt,
        'options': options,
        'correctIndex': correctIndex,
      };
}

class Quiz {
  final String id;
  final String title;
  final List<Question> questions;
  final DateTime createdAt;

  Quiz({required this.id, required this.title, required this.questions, required this.createdAt});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      questions: (json['questions'] as List).map((e) => Question.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class Attempt {
  final String gameId;
  final String playerName;
  final List<int> selectedIndices; // length == num questions, -1 if not answered
  final int score; // number correct
  final DateTime playedAt;

  Attempt({required this.gameId, required this.playerName, required this.selectedIndices, required this.score, required this.playedAt});

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      gameId: json['gameId'] as String,
      playerName: json['playerName'] as String? ?? 'Anonymous',
      selectedIndices: (json['selectedIndices'] as List).map((e) => (e as num).toInt()).toList(),
      score: (json['score'] as num).toInt(),
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'playerName': playerName,
        'selectedIndices': selectedIndices,
        'score': score,
        'playedAt': playedAt.toIso8601String(),
      };
}