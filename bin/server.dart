import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'handlers.dart';
import 'queries.dart';
import 'auth/gcs_service.dart';
import 'common/handler_service.dart';
import 'text_constants.dart';
import 'logging_service.dart';
import 'middleware.dart';
import 'package:googleapis/logging/v2.dart' as logging;

void main(List<String> args) async {
  // final ip = InternetAddress('192.168.0.120');
  final ip = InternetAddress.anyIPv4;
  // final port = 3000;
  final port = 8080;
  ansiColorDisabled = false;
  Connection conn;
  while (true) {
    try {
      conn = await Connection.open(
        Endpoint(
            host: '127.0.0.1',
            port: 5432,
            database: 'tez_bazar_db',
            username: 'postgres',
            password: '9899'),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
          timeZone: 'Asia/Bishkek',
        ),
      );
      break;
    } catch (e) {
      print('Failed to connect to the database. Retrying in 5 seconds...');
      await Future.delayed(Duration(seconds: 5));
    }
  }
  final String credentialsJson =
      await File('bin/auth/tez-bazar-gc-2f2fad85308f.json').readAsString();
  final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
  final scopes = [
    logging.LoggingApi.loggingWriteScope,
  ];
  final client = await clientViaServiceAccount(credentials, scopes);
  final logging.LoggingApi api = logging.LoggingApi(client);
  final bucketName = 'products-tez-bazar';
  final googleCloudService = await GoogleCloudService.init(
      credentials: credentials, bucketName: bucketName);
  final loggingService =
      await LoggingService.init(api: api, credentials: credentials);
  DatabaseQueries dbQueries = DatabaseQueries(conn);

  HandlerService handlerService =
      HandlerService(db: dbQueries, gcs: googleCloudService);
  Handlers handlers = Handlers(
    db: dbQueries,
    gcs: googleCloudService,
    hs: handlerService,
    ls: loggingService,
  );

  final router = Router()
    ..get(DbFields.getMainData, handlers.getMainDataHandler)
    ..get(DbFields.getCategories, handlers.getCategoriesHandler)
    ..get(DbFields.getBanners, handlers.getBannersHandler)
    ..get(DbFields.allCategories, handlers.getListOfCategoriesHandler)
    ..get(DbFields.getProducts, handlers.getProductsHandler)
    ..post(DbFields.authWithGoogle, handlers.authWithGoogleHandler)
    ..get(DbFields.getActiveProducts, handlers.getActiveProductsHandler)
    ..get(DbFields.getArchiveProducts, handlers.getArchiveProductsHandler)
    //Post requests
    ..get(DbFields.search, handlers.getSearchProduct)
    ..get('/get_limit', handlers.getLimitHandler)
    ..post(DbFields.userProfileUpdate, handlers.userProfileUpdateHandler)
    ..post(DbFields.userProfileUpdateWithFile,
        handlers.userProfileUpdateWithFileHandler)
    ..post(DbFields.addProduct, handlers.addProductHandler)
    ..post(DbFields.bugReport, handlers.bugReportHandler)
    ..post(DbFields.addAdWithFile, handlers.addProductWithFileHandler)
    ..post(DbFields.editAd, handlers.editProductHandler)
    ..post(DbFields.archivedAd, handlers.archivedProductHandler)
    ..post(DbFields.moderateAd, handlers.moderateProductHandler)
    ..post(DbFields.removeAd, handlers.removeProductHandler)
    // Обработчик для несуществующих маршрутов
    ..all('/<ignored|.*>', (Request request) {
      loggingService.logError(
        'Перенаправление с несуществующего маршрута: ${request.method} ${request.requestedUri}',
      );
      return Response.found('/');
    });

  final handler = Pipeline()
      .addMiddleware(customLogRequestsMiddleware(loggingService))
      .addHandler(router.call);

  final server = await serve(handler, ip, port);
  loggingService.logSys('${server.port}');
}
