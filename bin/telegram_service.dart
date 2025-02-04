import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendMessageToTelegram(String messageText) async {
  final String apiToken = '7689844397:AAGYBOsA-6bU_r-4cLFl2WcUnIkVIFOHzgw';
  final int chatId = 6040761411; // Замените на ID чата или пользователя

  final String url = 'https://api.telegram.org/bot$apiToken/sendMessage';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'chat_id': chatId,
      'text': messageText,
    }),
  );

  if (response.statusCode == 200) {
  } else {
    print('Ошибка при отправке сообщения в Telegram: ${response.body}');
  }
}
