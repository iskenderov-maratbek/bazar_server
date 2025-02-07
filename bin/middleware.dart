import 'package:shelf/shelf.dart';
import 'logging_service.dart';

Middleware customLogRequestsMiddleware(LoggingService loggingService) {
  return (Handler handler) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final response = await handler(request);

        final duration = DateTime.now().difference(startTime);
        loggingService.logSys(
            'Запрос обработан: ${request.method} ${request.requestedUri} (${duration.inMilliseconds} ms)');

        return response;
      } catch (error, stackTrace) {
        final duration = DateTime.now().difference(startTime);
        loggingService.logError(
          'Ошибка при обработке запроса: ${request.method} ${request.requestedUri} (${duration.inMilliseconds} ms) errorInfo: $error stackTrace: $stackTrace',
        );
        return Response.internalServerError(body: 'Internal Server Error');
      }
    };
  };
}
