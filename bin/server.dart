import 'dart:io';
// import 'package:hive/hive.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'handlers.dart';
import 'queries.dart';

void main(List<String> args) async {
  final ip = InternetAddress('192.168.1.103');
  final port = 3000;

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
  print(Directory.current.path);
  // Hive.init('${Directory.current.path}\\hive');
  // var box = await Hive.openBox('codes_database');

  // ConfirmCodes codes = ConfirmCodes(box);
  DatabaseQueries dbQueries = DatabaseQueries(conn);
  Handlers handlers = Handlers(dbQueries);

  final router = Router()
    // ..get('/', handlers.rootHandler)
    ..get('/categories', handlers.getCategoriesHandler)
    ..get('/products', handlers.getProductsHandler)
    ..post('/authWithGoogle', handlers.authWithGoogleHandler)
    ..get('/getProductInfo', handlers.getProductInfoHandler);
  // ..post('/send-code-email', handlers.sendCodeEmail)
  // ..post('/login-with-number', handlers.loginWithNumber)
  // ..post('/confirm-code', handlers.confirmCode);

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
