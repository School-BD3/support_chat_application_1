import 'package:flutter/material.dart';

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
      home: const SupportChatHomeScreen(),
    );
  }
}

class SupportChatHomeScreen extends StatelessWidget {
  const SupportChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат служби підтримки'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 80, color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              'Служба підтримки',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Завантаження повідомлень буде додано далі',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
