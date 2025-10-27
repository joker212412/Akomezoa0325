import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_models.dart';

class StorageService {
  static const String _gamesKey = 'saved_games_v1';
  static const String _attemptsKey = 'game_attempts_v1';
  static const String _apiKeyKey = 'mistral_api_key_v1';

  Future<void> storeApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<List<Quiz>> listGames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gamesKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Quiz.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveGame(Quiz quiz) async {
    final prefs = await SharedPreferences.getInstance();
    final games = await listGames();
    final exists = games.any((g) => g.id == quiz.id);
    if (!exists) {
      games.add(quiz);
      await prefs.setString(_gamesKey, jsonEncode(games.map((g) => g.toJson()).toList()));
    }
  }

  Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final games = await listGames();
    final filtered = games.where((g) => g.id != gameId).toList();
    await prefs.setString(_gamesKey, jsonEncode(filtered.map((g) => g.toJson()).toList()));

    // Also delete related attempts
    final attempts = await listAllAttempts();
    final remaining = attempts.where((a) => a.gameId != gameId).toList();
    await prefs.setString(_attemptsKey, jsonEncode(remaining.map((a) => a.toJson()).toList()));
  }

  Future<List<Attempt>> listAllAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attemptsKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Attempt.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Attempt>> getAttemptsForGame(String gameId) async {
    final all = await listAllAttempts();
    return all.where((a) => a.gameId == gameId).toList()..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  }

  Future<void> addAttempt(Attempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await listAllAttempts();
    attempts.add(attempt);
    await prefs.setString(_attemptsKey, jsonEncode(attempts.map((a) => a.toJson()).toList()));
  }
}