import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/mistral_service.dart';
import '../services/storage_service.dart';
import '../utils/pdf_extractor.dart';
import '../models/quiz_models.dart';
import 'quiz_page.dart';
import 'game_list_page.dart';

class GameFormPage extends StatefulWidget {
  static const String routeName = '/';
  const GameFormPage({super.key});

  @override
  State<GameFormPage> createState() => _GameFormPageState();
}

class _GameFormPageState extends State<GameFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Quiz généré');
  final _textController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _numController = TextEditingController(text: '10');
  String _model = MistralService.defaultModel;
  bool _usePdf = false;
  String? _pickedPdfPath;
  bool _isLoading = false;

  final _storage = StorageService();
  final _mistral = MistralService();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final saved = await _storage.loadApiKey();
    if (saved != null && saved.isNotEmpty) {
      _apiKeyController.text = saved;
      setState(() {});
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      _pickedPdfPath = result.files.single.path!;
      setState(() {});
    }
  }

  Future<void> _onGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    final apiKey = _apiKeyController.text.trim();
    final title = _titleController.text.trim();
    final requested = int.tryParse(_numController.text.trim()) ?? 10;

    String sourceText = _textController.text.trim();
    if (_usePdf) {
      if (_pickedPdfPath == null) {
        _showSnack('Veuillez choisir un fichier PDF.');
        return;
      }
      try {
        sourceText = await PdfExtractor.extractTextFromPath(_pickedPdfPath!);
      } catch (e) {
        _showSnack('Erreur extraction PDF: $e');
        return;
      }
    }

    if (sourceText.isEmpty) {
      _showSnack('Veuillez fournir un texte ou un PDF.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _storage.storeApiKey(apiKey);
      final quiz = await _mistral.generateQuiz(
        apiKey: apiKey,
        title: title,
        sourceText: sourceText,
        numQuestions: requested,
        model: _model,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizPage(quiz: quiz, fromLibrary: false),
        ),
      );
    } catch (e) {
      _showSnack('Erreur génération: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un jeu (Mistral)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Liste des jeux',
            onPressed: () => Navigator.pushNamed(context, GameListPage.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Clé API Mistral',
                    hintText: 'sk-... (conservez-la localement)',
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  obscureText: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'Clé API requise' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Titre du quiz', prefixIcon: Icon(Icons.title)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Titre requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _numController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nb questions (5-20)'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null; // default 10 if empty
                          final n = int.tryParse(v);
                          if (n == null) return 'Nombre';
                          if (n < 5 || n > 20) return '5 à 20';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _model,
                  items: const [
                    DropdownMenuItem(value: 'mistral-small-latest', child: Text('mistral-small-latest')),
                    DropdownMenuItem(value: 'mistral-medium-latest', child: Text('mistral-medium-latest')),
                    DropdownMenuItem(value: 'mistral-large-latest', child: Text('mistral-large-latest')),
                  ],
                  onChanged: (v) => setState(() => _model = v ?? MistralService.defaultModel),
                  decoration: const InputDecoration(labelText: 'Modèle'),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _usePdf,
                  onChanged: (v) => setState(() => _usePdf = v),
                  title: const Text('Utiliser un PDF comme source'),
                ),
                if (_usePdf) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(_pickedPdfPath == null ? 'Aucun fichier choisi' : File(_pickedPdfPath!).path.split('/').last),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(onPressed: _pickPdf, icon: const Icon(Icons.upload_file), label: const Text('Choisir PDF')),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Texte source (base du quiz)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    minLines: 6,
                    maxLines: 12,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Texte requis si aucun PDF' : null,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _onGenerate,
                  icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.bolt),
                  label: const Text('Générer le jeu'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Astuce: si le champ est vide, 10 questions par défaut seront générées (et bornées 5-20).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}