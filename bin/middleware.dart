import 'package:shelf/shelf.dart';
import 'logging_service.dart';
import 'package:logging/logging.dart';

Middleware customLogRequestsMiddleware(LoggingService loggingService) {
  final log = Logger('Request');
  return (Handler handler) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final response = await handler(request);

        final duration = DateTime.now().difference(startTime);
        loggingService.logSys(
            'Запрос обработан: ${request.method} ${request.requestedUri} (${duration.inMilliseconds} ms)');
        log.info(
            '${request.method} ${request.requestedUri} -> ${response.statusCode} (${duration.inMilliseconds} ms)');

        return response;
      } catch (error, stackTrace) {
        final duration = DateTime.now().difference(startTime);
        loggingService.logError(
          'Ошибка при обработке запроса: ${request.method} ${request.requestedUri} (${duration.inMilliseconds} ms)',
        );
        log.severe(
            'Ошибка при обработке запроса: ${request.method} ${request.requestedUri} (${duration.inMilliseconds} ms)',
            error,
            stackTrace);

        return Response.internalServerError(body: 'Internal Server Error');
      }

      
    };
  };
}
