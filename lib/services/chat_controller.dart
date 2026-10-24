import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'fake_chat_api.dart';


class ChatController {
  ChatController({
    required this._api,
    required List<ChatMessage> initialMessages,
  }) : _messages = List<ChatMessage>.from(initialMessages) {
    _publish();
  }

  final FakeChatApi _api;

  final StreamController<List<ChatMessage>> _messageController =
      StreamController<List<ChatMessage>>.broadcast();

  final ValueNotifier<bool> isTyping = ValueNotifier<bool>(false);

  List<ChatMessage> _messages;
  Timer? _replyTimer;
  bool _disposed = false;
  int _nextMessageId = 0;

  Stream<List<ChatMessage>> get messagesStream => _messageController.stream;

  List<ChatMessage> get currentMessages =>
      List<ChatMessage>.unmodifiable(_messages);

  void _publish() {
    if (_disposed || _messageController.isClosed) return;

    _messageController.add(List<ChatMessage>.unmodifiable(_messages));
  }

  void markAllAsRead() {
    if (_disposed) return;

    _messages = _messages.map((message) {
      if (message.sender == MessageSender.operator && !message.isRead) {
        return message.copyWith(isRead: true);
      }
      return message;
    }).toList();

    _publish();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty || _disposed) return;

    final id =
        'user_${DateTime.now().microsecondsSinceEpoch}_'
        '${_nextMessageId++}';

    final message = ChatMessage(
      id: id,
      text: trimmed,
      sender: MessageSender.user,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    _messages = [..._messages, message];
    _publish();

    try {
      await _api.sendMessage(trimmed);

      if (_disposed) return;

      _updateStatus(id, MessageStatus.delivered);
      _scheduleOperatorReply();
    } catch (_) {
      if (_disposed) return;

      _updateStatus(id, MessageStatus.failed);
    }
  }

  Future<void> retryMessage(String id) async {
    if (_disposed) return;

    final index = _messages.indexWhere((message) => message.id == id);

    if (index == -1 || _messages[index].status != MessageStatus.failed) {
      return;
    }

    final text = _messages[index].text;

    _updateStatus(id, MessageStatus.sending);

    try {
      await _api.sendMessage(text);

      if (_disposed) return;

      _updateStatus(id, MessageStatus.delivered);
      _scheduleOperatorReply();
    } catch (_) {
      if (_disposed) return;

      _updateStatus(id, MessageStatus.failed);
    }
  }

  void _updateStatus(String id, MessageStatus status) {
    if (_disposed) return;

    _messages = _messages.map((message) {
      if (message.id == id) {
        return message.copyWith(status: status);
      }
      return message;
    }).toList();

    _publish();
  }

  void _scheduleOperatorReply() {
    if (_disposed) return;

    if (_replyTimer?.isActive ?? false) return;

    isTyping.value = true;

    _replyTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final reply = await _api.generateOperatorReply();

        if (_disposed) return;

        _messages = [..._messages, reply];
        _publish();
      } catch (_) {
      } finally {
        if (!_disposed) {
          isTyping.value = false;
        }
      }
    });
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _replyTimer?.cancel();
    isTyping.dispose();
    _messageController.close();
  }
}
