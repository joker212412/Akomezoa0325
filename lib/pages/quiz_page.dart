import 'package:flutter/material.dart';

import '../models/quiz_models.dart';
import '../services/storage_service.dart';

class QuizPage extends StatefulWidget {
  final Quiz quiz;
  final bool fromLibrary;

  const QuizPage({super.key, required this.quiz, required this.fromLibrary});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<int> _selected; // -1 if not answered
  final _playerController = TextEditingController();
  final _storage = StorageService();
  bool _saving = false;
  bool _validated = false;

  @override
  void initState() {
    super.initState();
    _selected = List<int>.filled(widget.quiz.questions.length, -1);
  }

  int _computeScore() {
    int s = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_selected[i] == widget.quiz.questions[i].correctIndex) s++;
    }
    return s;
  }

  Future<void> _onValidate() async {
    final name = _playerController.text.trim().isEmpty ? 'Anonymous' : _playerController.text.trim();
    final score = _computeScore();

    await _storage.addAttempt(Attempt(
      gameId: widget.quiz.id,
      playerName: name,
      selectedIndices: List<int>.from(_selected),
      score: score,
      playedAt: DateTime.now(),
    ));

    setState(() => _validated = true);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Score'),
        content: Text('Vous avez obtenu $score / ${widget.quiz.questions.length}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _onSaveGame() async {
    setState(() => _saving = true);
    try {
      await _storage.saveGame(widget.quiz);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jeu enregistré dans la liste.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color? _tileColorFor(int qIndex, int optIndex) {
    if (!_validated) return null;
    final correct = widget.quiz.questions[qIndex].correctIndex;
    if (optIndex == correct) return Colors.green.withOpacity(0.12);
    if (_selected[qIndex] == optIndex && optIndex != correct) return Colors.red.withOpacity(0.12);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Liste des jeux',
            onPressed: () => Navigator.of(context).pushNamed('/games'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _playerController,
                      decoration: const InputDecoration(labelText: 'Nom du joueur (optionnel)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.quiz.questions.length,
                  itemBuilder: (context, index) {
                    final q = widget.quiz.questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q${index + 1}. ${q.prompt}', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            for (int i = 0; i < q.options.length; i++)
                              Container(
                                decoration: BoxDecoration(color: _tileColorFor(index, i), borderRadius: BorderRadius.circular(8)),
                                child: RadioListTile<int>(
                                  value: i,
                                  groupValue: _selected[index],
                                  onChanged: (v) {
                                    if (_validated) return; // lock after validation
                                    setState(() => _selected[index] = v ?? -1);
                                  },
                                  title: Text(q.options[i]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _validated ? null : _onValidate,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Valider réponses'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _onSaveGame,
                      icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('Enregistrer le jeu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}