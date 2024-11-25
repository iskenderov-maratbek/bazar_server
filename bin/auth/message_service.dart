// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';

// void sendAuthorizationCode(String recipientEmail, String code) async {
//   // Настройка SMTP сервера
//   final smtpServer = SmtpServer('smtp.gmail.com',
//       username: 'noreply@taxikg.app',
//       password: 'ataa vqdf gxyy uoen',
//       // Используйте порт 465 или 587 в зависимости от вашего провайдера
//       port: 587,
//       // Используйте ssl или tls в зависимости от требований безопасности вашего провайдера
//       ssl: false);

//   // Создание сообщения
//   final message = Message()
//     ..from = Address('noreply@taxikg.app', 'Taxikg')
//     ..recipients.add(recipientEmail)
//     ..subject = 'Your Authorization Code'
//     ..text = 'Your authorization code is: $code\n Your url: https://taxikg.app';

//   try {
//     final sendReport = await send(message, smtpServer);
//     print('Message sent: $sendReport');
//   } on MailerException catch (e) {
//     print('Message not sent\n${e.message}');
//     print('Message not sent\n${e.problems}');
//     for (var p in e.problems) {
//       print('Problem: ${p.code}: ${p.msg}');
//     }
//   }
// }
