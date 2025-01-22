import 'dart:io';
// import 'package:hive/hive.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:hive/hive.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'handlers.dart';
import 'queries.dart';
import 'auth/gcs_service.dart';
import 'common/handler_service.dart';
import 'text_constants.dart';
import 'handler_version.dart';
import 'hive_data.dart';

void main(List<String> args) async {
  // final ip = InternetAddress('13.60.255.190');
  final ip = InternetAddress.anyIPv4;
  final port = 8080;
  ansiColorDisabled = false;

  final conn = await Connection.open(
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

  final credentialsJson =
      await File('bin/auth/tez-bazar-gc-2f2fad85308f.json').readAsString();

  final bucketName = 'products-tez-bazar';
  final googleCloudService = await GoogleCloudService.init(
      credentialsJson: credentialsJson, bucketName: bucketName);

  DatabaseQueries dbQueries = DatabaseQueries(conn);

  HandlerService handlerService =
      HandlerService(db: dbQueries, gcs: googleCloudService);
  Handlers handlers =
      Handlers(db: dbQueries, gcs: googleCloudService, hs: handlerService);
  // Hive
  final path = Directory.current.path;
  Hive.init(path);
  final box = await Hive.openBox('mainbox');

  HiveData hiveData = HiveData(box: box);
  hiveData.setData(DbFields.homeVersionKey, '0.4.4');
  HandlerVersion handlerVersion = HandlerVersion(hiveData: hiveData);

  final router = Router()
    ..get(DbFields.getMainData, handlers.getMainDataHandler)
    ..get(DbFields.getHomeVersion, handlerVersion.gethomeVersionHandler)
    ..get(DbFields.getCategories, handlers.getCategoriesHandler)
    ..get(DbFields.getBanners, handlers.getBannersHandler)
    ..get(DbFields.allCategories, handlers.getListOfCategoriesHandler)
    ..get(DbFields.getProducts, handlers.getProductsHandler)
    ..post(DbFields.authWithGoogle, handlers.authWithGoogleHandler)
    ..get(DbFields.getActiveProducts, handlers.getActiveProductsHandler)
    ..get(DbFields.getArchiveProducts, handlers.getArchiveProductsHandler)
    //Post requests
    ..get(DbFields.search, handlers.getSearchProduct)
    ..post(DbFields.userProfileUpdate, handlers.userProfileUpdateHandler)
    ..post(DbFields.userProfileUpdateWithFile,
        handlers.userProfileUpdateWithFileHandler)
    ..post(DbFields.addAd, handlers.addProductHandler)
    ..post(DbFields.bugReport, handlers.bugReportHandler)
    ..post(DbFields.addAdWithFile, handlers.addProductWithFileHandler)
    ..post(DbFields.editAd, handlers.editProductHandler)
    ..post(DbFields.archivedAd, handlers.archivedProductHandler)
    ..post(DbFields.moderateAd, handlers.moderateProductHandler)
    ..post(DbFields.removeAd, handlers.removeProductHandler);

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final server = await serve(handler, ip, port);
  print('SERVER START ON: ${server.port}');
}
