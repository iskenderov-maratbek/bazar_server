import 'package:ansicolor/ansicolor.dart';
import 'package:googleapis/logging/v2.dart';
import 'telegram_service.dart';
import 'package:googleapis/logging/v2.dart' as logging;
import 'package:googleapis_auth/auth_io.dart';

class LoggingService {
  logging.LoggingApi api;
  AutoRefreshingAuthClient client;

  LoggingService._(this.api, this.client);

  static Future<LoggingService> init({
    required ServiceAccountCredentials credentials,
    required LoggingApi api,
  }) async {
    final scopes = [
      logging.LoggingApi.loggingWriteScope,
    ];
    final client = await clientViaServiceAccount(credentials, scopes);
    return LoggingService._(api, client);
  }

  Future<void> sendLogToGoogleCloud(String message, String severity) async {
    final logName = 'projects/tez-bazar-gc/logs/tez_bazar_server';
    final logEntry = logging.LogEntry()
      ..logName = logName
      ..resource = (logging.MonitoredResource()..type = 'global')
      ..severity = severity
      ..textPayload = message;

    final writeRequest = logging.WriteLogEntriesRequest()..entries = [logEntry];

    try {
      await api.entries.write(writeRequest);
    } catch (e) {
      sendMessageToTelegram(
          ' Ошибка при отправке лога в Google Cloud Service: $e');
    }
  }

  logHandler(message) {
    sendLogToGoogleCloud(message, 'INFO');
    final severePen = AnsiPen()..xterm(227);
    print(severePen('[--HANDLER] $message'));
  }

  logSys(String message) {
    sendLogToGoogleCloud(message, 'INFO');
    final infoPen = AnsiPen()..xterm(246);
    print(infoPen('[---SYSTEM] $message'));
  }

  logError(message) {
    sendLogToGoogleCloud(message, 'ERROR');
    sendMessageToTelegram('ERROR: $message');
    final errorPen = AnsiPen()..xterm(197);
    print(errorPen('[----ERROR] $message'));
  }

// В конце работы приложения
  void disposeLogging() {
    client.close();
  }
}
