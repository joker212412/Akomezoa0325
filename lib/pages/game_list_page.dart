import 'package:flutter/material.dart';

import '../models/quiz_models.dart';
import '../services/storage_service.dart';
import 'quiz_page.dart';

class GameListPage extends StatefulWidget {
  static const String routeName = '/games';
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  final _storage = StorageService();
  late Future<List<Quiz>> _futureGames;

  @override
  void initState() {
    super.initState();
    _futureGames = _storage.listGames();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureGames = _storage.listGames();
    });
  }

  Future<void> _deleteGame(String gameId) async {
    await _storage.deleteGame(gameId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des jeux'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Quiz>>(
          future: _futureGames,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final games = snapshot.data ?? [];
            if (games.isEmpty) {
              return const Center(child: Text('Aucun jeu enregistré pour le moment.'));
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final g = games[index];
                  return _GameTile(quiz: g, storage: _storage, onChanged: _refresh, onDelete: _deleteGame);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameTile extends StatefulWidget {
  final Quiz quiz;
  final StorageService storage;
  final Future<void> Function() onChanged;
  final Future<void> Function(String gameId) onDelete;

  const _GameTile({required this.quiz, required this.storage, required this.onChanged, required this.onDelete});

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile> {
  bool _expanded = false;
  late Future<List<Attempt>> _futureAttempts;

  @override
  void initState() {
    super.initState();
    _futureAttempts = widget.storage.getAttemptsForGame(widget.quiz.id);
  }

  Future<void> _refreshAttempts() async {
    setState(() {
      _futureAttempts = widget.storage.getAttemptsForGame(widget.quiz.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.quiz.title),
            subtitle: Text('${widget.quiz.questions.length} questions • Créé le ${widget.quiz.createdAt.toLocal()}'),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Jouer',
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => QuizPage(quiz: widget.quiz, fromLibrary: true)),
                    );
                    await _refreshAttempts();
                  },
                ),
                IconButton(
                  tooltip: _expanded ? 'Masquer' : 'Historique',
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () async {
                    setState(() => _expanded = !_expanded);
                    if (_expanded) await _refreshAttempts();
                  },
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Supprimer le jeu ?'),
                        content: const Text('Cette action supprime aussi ses scores.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await widget.onDelete(widget.quiz.id);
                    }
                  },
                ),
              ],
            ),
          ),
          if (_expanded)
            FutureBuilder<List<Attempt>>(
              future: _futureAttempts,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }
                final attempts = snapshot.data ?? [];
                if (attempts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucune tentative enregistrée.'),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final a in attempts)
                        ListTile(
                          dense: true,
                          title: Text('${a.playerName} • ${a.score}/${widget.quiz.questions.length}'),
                          subtitle: Text(a.playedAt.toLocal().toString()),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}