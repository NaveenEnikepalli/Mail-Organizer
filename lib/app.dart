import 'package:flutter/material.dart';
import 'shell/mail_shell.dart';

class MailMindApp extends StatelessWidget {
  const MailMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mail Organizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
      ),
      home: const MailShell(),
    );
  }
}
