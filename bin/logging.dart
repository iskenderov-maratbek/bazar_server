import 'package:ansicolor/ansicolor.dart';

// logSys(String message) {
//   final infoPen = AnsiPen()..xterm(246);
//   print(infoPen('[---SYSTEM] $message'));
// }

logError(message) {
  final errorPen = AnsiPen()..xterm(197);
  print(errorPen('[----ERROR] $message'));
}

// logQuery(message) {
//   final severePen = AnsiPen()..xterm(045);
//   print(severePen('[----QUERY] $message'));
// }

// logHandler(message) {
//   final severePen = AnsiPen()..xterm(227);
//   print(severePen('[--HANDLER] $message'));
// }

// logInfo(message) {
//   final severePen = AnsiPen()..xterm(046);
//   print(severePen('[-----INFO] $message'));
// }
