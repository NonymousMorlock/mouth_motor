import 'package:flutter/material.dart';
import 'package:motor_mouth/counter/counter.dart';
import 'package:motor_mouth/l10n/l10n.dart';
import 'package:motor_mouth/src/tts/presentation/views/home_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motor Mouth',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme:
            ColorScheme.fromSwatch(
              brightness: Brightness.dark,
              primarySwatch: Colors.deepPurple,
            ).copyWith(
              secondary: Colors.amber,
            ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeView(),
    );
  }
}
