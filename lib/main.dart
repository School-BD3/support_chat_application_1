import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';

void main() {
  runApp(const SupportChatApp());
}

class SupportChatApp extends StatelessWidget {
  const SupportChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Чат служби підтримки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
