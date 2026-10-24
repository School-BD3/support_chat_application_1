import 'chat_message.dart';
import 'support_operator.dart';

class ChatInitialData {
  const ChatInitialData({required this.messages, required this.operator});

  final List<ChatMessage> messages;
  final SupportOperator operator;
}
