import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/quiz_models.dart';

class MistralService {
  static const String defaultModel = 'mistral-small-latest';
  static const String endpoint = 'https://api.mistral.ai/v1/chat/completions';

  Future<Quiz> generateQuiz({
    required String apiKey,
    required String title,
    required String sourceText,
    required int numQuestions,
    String model = defaultModel,
  }) async {
    final clamped = numQuestions.clamp(5, 20);
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(title: title, sourceText: sourceText, numQuestions: clamped);

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0.2,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Mistral API error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (decoded['choices'] as List).first['message']['content'] as String;
    final Map<String, dynamic> quizJson = jsonDecode(content) as Map<String, dynamic>;

    final questions = (quizJson['questions'] as List)
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();

    // Ensure three options per question and one correctIndex 0..2
    for (final q in questions) {
      if (q.options.length != 3 || q.correctIndex < 0 || q.correctIndex > 2) {
        throw Exception('Invalid quiz format returned by model.');
      }
    }

    final quiz = Quiz(
      id: const Uuid().v4(),
      title: quizJson['title']?.toString() ?? title,
      questions: questions,
      createdAt: DateTime.now(),
    );

    return quiz;
  }

  String _buildSystemPrompt() {
    return 'You generate multiple-choice quizzes strictly in JSON. Always return valid JSON only.'
        ' Do not include any explanations or markdown.'
        ' For each question, provide exactly 3 options and exactly one correct answer via correctIndex (0..2).';
  }

  String _buildUserPrompt({required String title, required String sourceText, required int numQuestions}) {
    return 'Generate a quiz in French with the following constraints:'
        '\n- Title: "$title"'
        '\n- Number of questions: $numQuestions (between 5 and 20)'
        '\n- Each question must have exactly 3 short options and a single correctIndex (0..2).'
        '\n- Keep questions concise, unambiguous, and derived only from the provided content.'
        '\n- Avoid trick questions and avoid repeating options.'
        '\n- Output JSON with this shape:'
        '\n{\n  "title": string,\n  "questions": [\n    {\n      "question": string,\n      "options": [string, string, string],\n      "correctIndex": number (0..2)\n    }\n  ]\n}'
        '\n\nContent to base the quiz on (in French):\n"""\n$sourceText\n"""';
  }
}