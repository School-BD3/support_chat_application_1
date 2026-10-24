import 'dart:async';
import 'dart:math';

import '../models/chat_initial_data.dart';
import '../models/chat_message.dart';
import '../models/support_operator.dart';

class FakeChatApi {
  FakeChatApi({
    this.failureRate = 0.2,
    this.emptyHistory = false,
    Random? random,
  }) : _random = random ?? Random() {
    if (failureRate < 0 || failureRate > 1) {
      throw ArgumentError.value(
        failureRate,
        'failureRate',
        'Має бути від 0 до 1',
      );
    }
  }

  final double failureRate;
  final bool emptyHistory;
  final Random _random;

  Future<T> _request<T>(T Function() respond, {int delayMs = 800}) async {
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    if (_random.nextDouble() < failureRate) {
      throw StateError('Сервер тимчасово недоступний');
    }

    return respond();
  }

  Future<List<ChatMessage>> loadHistory() {
    return _request(() {
      if (emptyHistory) {
        return <ChatMessage>[];
      }

      final now = DateTime.now();

      return [
        ChatMessage(
          id: 'message_1',
          text: 'Вітаємо у службі підтримки!',
          sender: MessageSender.operator,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: 'message_2',
          text: 'Добрий день! Маю запитання.',
          sender: MessageSender.user,
          createdAt: now.subtract(const Duration(minutes: 9)),
        ),
        ChatMessage(
          id: 'message_3',
          text: 'Звичайно! Чим можемо допомогти?',
          sender: MessageSender.operator,
          createdAt: now.subtract(const Duration(minutes: 8)),
        ),
      ];
    }, delayMs: 900);
  }

  Future<SupportOperator> loadOperator() {
    return _request(
      () => const SupportOperator(
        id: 'operator_1',
        name: 'Олена Коваль',
        department: 'Технічна підтримка',
        isOnline: true,
      ),
      delayMs: 650,
    );
  }

  Future<ChatInitialData> loadInitialData() async {
    final results = await Future.wait<Object>([loadHistory(), loadOperator()])
        .timeout(const Duration(seconds: 3));

    return ChatInitialData(
      messages: results[0] as List<ChatMessage>,
      operator: results[1] as SupportOperator,
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      throw ArgumentError('Повідомлення не може бути порожнім');
    }

    await _request(
      () => true,
      delayMs: 800,
    ).timeout(const Duration(seconds: 2));
  }

  Future<ChatMessage> generateOperatorReply() async {
    final delayMs = 2000 + _random.nextInt(3001);

    return _request(() {
      const replies = [
        'Дякуємо за звернення! Зараз допоможемо.',
        'Уточніть, будь ласка, деталі вашого питання.',
        'Ми перевіряємо інформацію.',
        'Спробуйте повторити дію ще раз.',
        'Ваше звернення передано на опрацювання.',
      ];

      return ChatMessage(
        id: 'operator_${DateTime.now().microsecondsSinceEpoch}',
        text: replies[_random.nextInt(replies.length)],
        sender: MessageSender.operator,
        createdAt: DateTime.now(),
        isRead: false,
      );
    }, delayMs: delayMs);
  }
}
