// handlers.dart
import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'queries.dart';

class Handlers {
  final DatabaseQueries dbQueries;

  Handlers(this.dbQueries);

  // Future<String> jsontransform(dataname, Request request) async {
  //   var result = await request
  //       .readAsString()
  //       .then((body) => jsonDecode(body) as Map<String, dynamic>);
  //   return result[dataname].toString();
  // }

  // Response rootHandler(Request req) {
  //   return Response('Hello, World!\n');
  // }

  Future<Response> getCategoriesHandler(Request request) async {
    final int offset = int.parse(request.url.queryParameters['offset'] ?? '0');
    final int limit = int.parse(request.url.queryParameters['limit'] ?? '10');
    final result = await dbQueries.getCategories(limit: limit, offset: offset);
    final categories = _resultToList(result);
    print('RESULT RESPONSE CATEGORY: $categories');
    return Response.ok(jsonEncode(categories),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> getProductsHandler(Request request) async {
    final int type = int.parse(request.url.queryParameters['type'] ?? '0');
    final int offset = int.parse(request.url.queryParameters['offset'] ?? '0');
    final int limit = int.parse(request.url.queryParameters['limit'] ?? '10');
    print('type: $type');
    final result =
        await dbQueries.getProducts(type: type, limit: limit, offset: offset);
    final products = _resultToList(result);
    print('RESULT RESPONSE PRODUCT: $products');
    return Response.ok(jsonEncode(products),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> getProductInfoHandler(Request request) async {
    final int id = int.parse(request.url.queryParameters['id'] ?? '0');
    print('id: $id');
    final result = await dbQueries.getProductInfo(id: id);
    final products = _resultToList(result);
    for (var item in products) {
      item.remove('user_id');
    }
    print('INFO FULL PRODUCT: $products');
    return Response.ok(jsonEncode({...products[0]}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> authWithGoogleHandler(Request request) async {
    print(' Auth with Google handler');
    final authData = await request.readAsString();
    final data = jsonDecode(authData);

    final String userId = data['id'];
    final String userName = data['name'];
    final String userEmail = data['email'];
    final String userPhoto = data['photo'];
    final String accessToken = data['accessToken'];

    // Проверка, существует ли пользователь
    final getUserData = await dbQueries.authUser(userId: userId);
    if (getUserData.isNotEmpty) {
      print(' User already exists');
      final result = _resultToListWithDateTime(getUserData);
      return Response.ok(jsonEncode({...result[0]}));
    } else {
      print('User does not exist, registering...');
      await dbQueries.registerUser(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          userPhoto: userPhoto,
          accessToken: accessToken);
      final getUserData = await dbQueries.authUser(userId: userId);
      if (getUserData.isNotEmpty) {
        print('REGISTERED');
        final result = _resultToListWithDateTime(getUserData);
        return Response.ok(jsonEncode({...result[0]}));
      } else {
        return Response.notFound('Ошибка регистрации. Что-то пошло не так');
      }
    }
  }

  List<Map<String, dynamic>> _resultToListWithDateTime(Result resultData) =>
      resultData.map((row) {
        final resultDataMap = row.toColumnMap();
        resultDataMap['created_at'] =
            resultDataMap['created_at']?.toIso8601String();
        return resultDataMap;
      }).toList();

  List<Map<String, dynamic>> _resultToList(Result resultData) =>
      resultData.map((row) => row.toColumnMap()).toList();
}
