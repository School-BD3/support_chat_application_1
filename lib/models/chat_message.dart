enum MessageSender { user, operator }

enum MessageStatus { sending, delivered, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.status = MessageStatus.delivered,
    this.isRead = true,
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime createdAt;
  final MessageStatus status;
  final bool isRead;

  ChatMessage copyWith({String? text, MessageStatus? status, bool? isRead}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      sender: sender,
      createdAt: createdAt,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
    );
  }
}
