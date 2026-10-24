import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_initial_data.dart';
import '../models/chat_message.dart';
import '../services/chat_controller.dart';
import '../services/fake_chat_api.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FakeChatApi _api = FakeChatApi(failureRate: 0.2);
  final TextEditingController _textController = TextEditingController();

  late Future<ChatInitialData> _initialDataFuture;

  ChatController? _chatController;
  Stream<List<ChatMessage>>? _messageStream;

  List<ChatMessage> _initialMessages = [];
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadChat();
  }

  Future<ChatInitialData> _loadChat() async {
    final generation = ++_loadGeneration;

    final data = await _api.loadInitialData();

    if (!mounted || generation != _loadGeneration) {
      return data;
    }

    _chatController?.dispose();

    final controller = ChatController(
      api: _api,
      initialMessages: data.messages,
    );

    _chatController = controller;
    _messageStream = controller.messagesStream;
    _initialMessages = controller.currentMessages;

    return data;
  }

  void _reloadData() {
    _chatController?.dispose();
    _chatController = null;
    _messageStream = null;
    _initialMessages = [];

    setState(() {
      _initialDataFuture = _loadChat();
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final controller = _chatController;
    if (controller == null) return;

    _textController.clear();

    await controller.sendMessage(text);

    if (!mounted) return;
  }

  Future<void> _retryMessage(String id) async {
    await _chatController?.retryMessage(id);

    if (!mounted) return;
  }

  String _formatTime(DateTime date) {
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _statusText(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'Надсилається...';
      case MessageStatus.delivered:
        return 'Доставлено';
      case MessageStatus.failed:
        return 'Не доставлено';
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Завантаження повідомлень...'),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Не вдалося завантажити чат',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _reloadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторити'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Історія повідомлень порожня',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Почніть розмову зі службою підтримки'),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                if (isUser) ...[
                  const SizedBox(width: 10),
                  Text(
                    _statusText(message.status),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.status == MessageStatus.failed
                          ? Colors.red
                          : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
            if (isUser && message.status == MessageStatus.failed)
              TextButton.icon(
                onPressed: () => _retryMessage(message.id),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Повторити'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadCounter() {
    final stream = _messageStream;

    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<List<ChatMessage>>(
      stream: stream,
      initialData: _initialMessages,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];

        final unread = messages.where((message) {
          return message.sender == MessageSender.operator && !message.isRead;
        }).length;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.mark_chat_unread_outlined),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChat(ChatInitialData data) {
    final controller = _chatController;
    final stream = _messageStream;

    if (controller == null || stream == null) {
      return _buildLoading();
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.support_agent)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.operator.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(data.operator.department),
                    Text(
                      data.operator.isOnline ? '● Онлайн' : '● Не в мережі',
                      style: TextStyle(
                        color: data.operator.isOnline
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: stream,
            initialData: _initialMessages,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Помилка потоку: ${snapshot.error}'));
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return _buildEmpty();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(messages[index]);
                },
              );
            },
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: controller.isTyping,
          builder: (context, isTyping, child) {
            if (!isTyping) return const SizedBox.shrink();

            return const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Оператор друкує...'),
                ],
              ),
            );
          },
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Введіть повідомлення...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  tooltip: 'Надіслати',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат служби підтримки'),
        centerTitle: true,
        actions: [
          _buildUnreadCounter(),
          IconButton(
            onPressed: () {
              _chatController?.markAllAsRead();
            },
            icon: const Icon(Icons.done_all),
            tooltip: 'Позначити прочитаними',
          ),
          IconButton(
            onPressed: _reloadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити чат',
          ),
        ],
      ),
      body: FutureBuilder<ChatInitialData>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error!);
          }

          if (!snapshot.hasData) {
            return _buildEmpty();
          }

          return _buildChat(snapshot.data!);
        },
      ),
    );
  }

  @override
  void dispose() {
    _loadGeneration++;
    _chatController?.dispose();
    _textController.dispose();
    super.dispose();
  }
}
