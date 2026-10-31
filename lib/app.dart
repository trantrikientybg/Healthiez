import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'navigation/main_shell.dart';

class HealthiezApp extends StatelessWidget {
  const HealthiezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthiez',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}