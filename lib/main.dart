import 'package:flutter/material.dart';
import 'pages/game_form_page.dart';
import 'pages/game_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuizMistralApp());
}

class QuizMistralApp extends StatelessWidget {
  const QuizMistralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Mistral',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: GameFormPage.routeName,
      routes: {
        GameFormPage.routeName: (_) => const GameFormPage(),
        GameListPage.routeName: (_) => const GameListPage(),
      },
    );
  }
}