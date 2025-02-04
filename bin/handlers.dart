import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'queries.dart';
import 'auth/gcs_service.dart';
import 'text_constants.dart';
import 'logging_service.dart';
import 'common/handler_service.dart';

class Handlers {
  final DatabaseQueries db;
  final GoogleCloudService gcs;
  final HandlerService hs;
  final LoggingService ls;
  Handlers({
    required this.db,
    required this.gcs,
    required this.hs,
    required this.ls,
  });

  Future<Response> userProfileUpdateHandler(Request request) async {
    try {
      Map<String, dynamic> data;
      final contentType = request.headers[DbFields.contentTypeKey];
      final token = request.headers[DbFields.authKey];
      final id = request.headers['userid'];
      if (!contentType!.contains(DbFields.applicationJson)) {
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, id)) {
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      final requestBody = await request.readAsString();
      data = jsonDecode(requestBody);
      final result = await db.updateUserData(
        id: id!,
        name: data[DbFields.userNAME],
        phone: data[DbFields.userPHONE],
        whatsapp: data[DbFields.userWHATSAPP],
        location: data[DbFields.userLOCATION],
      );

      return result
          ? Response.ok(jsonEncode({'status': 'success'}))
          : Response(
              404,
              body: 'Unknown error',
              headers: {DbFields.contentTypeKey: DbFields.applicationJson},
            );
    } catch (e) {
      ls.logError(e);
      return Response(
        410,
        body: 'Error updating data',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> userProfileUpdateWithFileHandler(Request request) async {
    try {
      final contentType = request.headers[DbFields.contentTypeKey];
      String? profilePhoto;
      Map<String, dynamic> data;
      final token = request.headers[DbFields.authKey];
      final id = request.headers['userid'];
      if (!contentType!.contains(DbFields.multipartFormData)) {
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, id)) {
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.getJsonAndFile(request)) {
        return Response(
          412,
          body: 'Error uploading image',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      profilePhoto = await gcs.uploadFile(
          file: hs.file!,
          fileName: '${id!}-',
          folder: DbFields.userPROFILEPHOTOPATH,
          isUserProfilePhoto: true);

      data = hs.data;
      if (data['old_photo'] != null) {
        final removeFileName = data['old_photo'];
        String delFileName = removeFileName
            .replaceAll(
                'https://storage.googleapis.com/products-tez-bazar/', '')
            .replaceAll('${DbFields.userPROFILEPHOTOPATH}/', '')
            .replaceAll('.jpg', '');
        await gcs.deleteFile(
            fileName: delFileName, folder: DbFields.userPROFILEPHOTOPATH);
      }

      final result = await db.updateUserData(
        id: id,
        name: data[DbFields.userNAME],
        phone: data[DbFields.userPHONE],
        whatsapp: data[DbFields.userWHATSAPP],
        location: data[DbFields.userLOCATION],
        profilePhoto: profilePhoto,
      );

      return result
          ? Response.ok(jsonEncode({'photo': profilePhoto}))
          : Response(
              404,
              body: 'Unknown error',
              headers: {DbFields.contentTypeKey: DbFields.applicationJson},
            );
    } catch (e) {
      ls.logError(e);
      return Response(
        412,
        body: 'Error uploading image',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> addProductHandler(Request request) async {
    try {
      Map<String, dynamic> data;
      final contentType = request.headers[DbFields.contentTypeKey];
      final token = request.headers[DbFields.authKey];
      final id = request.headers['userid'];
      if (!contentType!.contains(DbFields.applicationJson)) {
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, id)) {
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      final limitProduct = await db.getLimit(id: id!);
      if (limitProduct >= 4) {
        return Response(
          244,
          body: 'You have reached the limit of adding products',
          headers: {
            DbFields.contentTypeKey: DbFields.applicationJson,
            'limit': limitProduct
          },
        );
      }

      final requestBody = await request.readAsString();
      data = jsonDecode(requestBody);

      final result = await db.addUserProduct(
        name: data[DbFields.productNAME],
        description: data[DbFields.productDESCRIPTION],
        price: data[DbFields.productPRICE],
        priceType: data[DbFields.productPRICETYPE],
        location: data[DbFields.productLOCATION],
        delivery: data[DbFields.productDELIVERY],
        categoryId: data[DbFields.productCATEGORYID],
        userId: id,
      );
      return result.isNotEmpty
          ? Response.ok(jsonEncode({'id': result[0]}))
          : Response(
              404,
              body: 'Unknown error',
              headers: {DbFields.contentTypeKey: DbFields.applicationJson},
            );
    } catch (e) {
      ls.logError(e);
      return Response(
        410,
        body: 'Error updating data',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> addProductWithFileHandler(Request request) async {
    try {
      Map<String, dynamic> data;
      List<String>? photos;
      final contentType = request.headers[DbFields.contentTypeKey];
      final token = request.headers[DbFields.authKey];
      final id = request.headers['userid'];
      if (!contentType!.contains(DbFields.multipartFormData)) {
        ls.logError(request.headers);
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, id)) {
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.getJsonAndFiles(request)) {
        return Response(
          412,
          body: 'Error uploading image',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      data = hs.data;
      photos = await gcs.uploadFiles(
          files: hs.files!,
          fileNamePrefix: 'product-',
          folder: DbFields.productPHOTOPATH);
      final result = await db.addUserProduct(
        name: data[DbFields.productNAME],
        description: data[DbFields.productDESCRIPTION],
        price: data[DbFields.productPRICE],
        priceType: data[DbFields.productPRICETYPE],
        location: data[DbFields.productLOCATION],
        delivery: data[DbFields.productDELIVERY],
        categoryId: data[DbFields.productCATEGORYID],
        userId: id!,
        photos: photos,
      );
      return result.isNotEmpty
          ? Response.ok(jsonEncode({'id': result.first, 'photos': photos}))
          : Response(
              404,
              body: 'Unknown error',
              headers: {DbFields.contentTypeKey: DbFields.applicationJson},
            );
    } catch (e) {
      ls.logError(e);
      return Response(
        412,
        body: 'Error uploading image',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> editProductHandler(Request request) async {
    try {
      Map<String, dynamic> data;
      final contentType = request.headers[DbFields.contentTypeKey];
      final token = request.headers[DbFields.authKey];
      final id = request.headers['userid'];
      final productId = request.headers['productid'];
      if (!contentType!.contains(DbFields.applicationJson)) {
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, id, productId: int.parse(productId!))) {
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      final requestBody = await request.readAsString();
      data = jsonDecode(requestBody);

      final result = await db.editUserProduct(
        id: data[DbFields.productID],
        name: data[DbFields.productNAME],
        description: data[DbFields.productDESCRIPTION],
        price: data[DbFields.productPRICE],
        priceType: data[DbFields.productPRICETYPE],
        location: data[DbFields.productLOCATION],
        delivery: data[DbFields.productDELIVERY],
        categoryId: data[DbFields.productCATEGORYID],
      );
      return result
          ? Response.ok(jsonEncode({"status": "success"}))
          : Response(
              404,
              body: 'Unknown error',
              headers: {DbFields.contentTypeKey: DbFields.applicationJson},
            );
    } catch (e) {
      ls.logError(e);
      return Response(
        410,
        body: 'Error updating data',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> removeProductHandler(Request request) async {
    try {
      final contentType = request.headers[DbFields.contentTypeKey];
      final token = request.headers[DbFields.authKey];
      final userId = request.headers['userid'];
      final productId = int.parse(request.headers['productid']!);

      if (!contentType!.contains(DbFields.applicationJson)) {
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, userId, productId: productId)) {
        ls.logError('token $token ; userId $userId ; productId $productId');
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      List<String>? removePhotos = await db.getPhotoUrl(productId: productId);
      if (removePhotos != null && removePhotos.isNotEmpty) {
        List<String> fileNames = removePhotos.map((url) {
          return url
              .replaceAll(
                  'https://storage.googleapis.com/products-tez-bazar/', '')
              .replaceAll('${DbFields.productPHOTOPATH}/', '');
        }).toList();
        String folder = DbFields.productPHOTOPATH;
        await gcs.deleteFiles(fileNames: fileNames, folder: folder);
      }
      final result = await db.removeUserProduct(
        productId: productId,
      );
      return result
          ? Response.ok(jsonEncode({'status': 'success'}))
          : Response(
              404,
              body: 'Unknown error',
              headers: {DbFields.contentTypeKey: DbFields.applicationJson},
            );
    } catch (e) {
      ls.logError(e);
      return Response(
        410,
        body: 'Error updating data $e',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> getCategoriesHandler(Request request) async {
    try {
      final categories = _resultToEnd(await db.getCategories());
      return Response.ok(jsonEncode(categories),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getBannersHandler(Request request) async {
    try {
      final banners = _resultToEnd(await db.getBanners());
      return Response.ok(jsonEncode(banners),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getMainDataHandler(Request request) async {
    try {
      final categories = _resultToEnd(await db.getCategories());
      final banners = _resultToEnd(await db.getBanners());
      final result = [
        {'categories': categories},
        {'banners': banners}
      ];
      return Response.ok(jsonEncode(result),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getProductsHandler(Request request) async {
    try {
      final int categoryId =
          int.parse(request.url.queryParameters['category_id'] ?? '0');
      final int offset =
          int.parse(request.url.queryParameters['offset'] ?? '0');
      final int limit = int.parse(request.url.queryParameters['limit'] ?? '5');
      final result = await db.getProducts(
          categoryId: categoryId, limit: limit, offset: offset);
      final products = _resultToEnd(result);
      return Response.ok(jsonEncode(products),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getSearchProduct(Request request) async {
    try {
      final String name = request.url.queryParameters['name'] ?? '';
      final int offset =
          int.parse(request.url.queryParameters['offset'] ?? '0');
      final int limit = int.parse(request.url.queryParameters['limit'] ?? '5');

      final result = await db.getSearchProduct(
        name: name,
        offset: offset,
        limit: limit,
      );
      final products = _resultToEnd(result);
      for (var item in products) {
        item.remove('user_id');
      }
      return Response.ok(jsonEncode(products),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getActiveProductsHandler(Request request) async {
    try {
      final id = request.url.queryParameters['id'] ?? '0';
      final offset = request.url.queryParameters['offset'] ?? '0';
      final limit = request.url.queryParameters['limit'] ?? '0';
      final resultActive =
          await db.getActiveUserProducts(id: id, offset: offset, limit: limit);
      var result = _resultToEnd(resultActive);
      return Response.ok(jsonEncode(result),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getArchiveProductsHandler(Request request) async {
    try {
      final id = request.url.queryParameters['id'] ?? '0';
      final offset = request.url.queryParameters['offset'] ?? '0';
      final limit = request.url.queryParameters['limit'] ?? '0';
      final resultArchive =
          await db.getArchiveProducts(id: id, offset: offset, limit: limit);
      var result = _resultToEnd(resultArchive);
      return Response.ok(jsonEncode(result),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getListOfCategoriesHandler(Request request) async {
    try {
      final result = await db.getListOfCategories();
      final categories = _resultToEnd(result);
      return Response.ok(jsonEncode(categories));
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error getting data $e ');
    }
  }

  Future<Response> getLimitHandler(Request request) async {
    try {
      final userId = request.headers['userid'];
      final result = await db.getLimit(id: userId!);
      return Response.ok(jsonEncode({'limit': result}));
    } catch (e) {
      ls.logError(e);
      return Response(
        404,
        body: 'Unknown error',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> archivedProductHandler(Request request) async {
    try {
      print(request.headers);
      final contentType = request.headers[DbFields.contentTypeKey];
      final token = request.headers[DbFields.authKey];
      final userId = request.headers['userid'];
      final productId = int.parse(request.headers['productid']!);
      if (!contentType!.contains(DbFields.applicationJson)) {
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, userId, productId: productId)) {
        ls.logError('token $token ; userId $userId ; productId $productId');
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      final result = await db.archivedUserProduct(productId: productId);

      if (result) {
        return Response.ok(jsonEncode({'status': 'success'}));
      } else {
        ls.logError(result);
        return Response(
          404,
          body: 'Unknown error',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
    } catch (e) {
      ls.logError(e);
      return Response(
        410,
        body: 'Error updating data',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> moderateProductHandler(Request request) async {
    try {
      final contentType = request.headers[DbFields.contentTypeKey];
      final token = request.headers[DbFields.authKey];
      final userId = request.headers['userid'];
      final productId = int.parse(request.headers['productid']!);

      if (!contentType!.contains(DbFields.applicationJson)) {
        return Response(
          413,
          body: 'Content-Type is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
      if (!await hs.tokenCheck(token, userId, productId: productId)) {
        ls.logError('token $token ; userId $userId ; productId $productId');
        return Response(
          411,
          body: 'Token is invalid',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }

      final result = await db.moderateUserProduct(productId: productId);

      if (result) {
        return Response.ok(jsonEncode({'status': 'success'}));
      } else {
        ls.logError(result);
        return Response(
          404,
          body: 'Unknown error',
          headers: {DbFields.contentTypeKey: DbFields.applicationJson},
        );
      }
    } catch (e) {
      ls.logError(e);
      return Response(
        410,
        body: 'Error updating data',
        headers: {DbFields.contentTypeKey: DbFields.applicationJson},
      );
    }
  }

  Future<Response> authWithGoogleHandler(Request request) async {
    try {
      final authData = await request.readAsString();
      final data = jsonDecode(authData);
      final String accessToken = data[DbFields.userTOKEN];
      final String userId = data[DbFields.userID];
      final String userName = data[DbFields.userNAME];
      final String userEmail = data[DbFields.userEMAIL];
      final getUserData = await db.authUser(userId: userId);

      if (getUserData.isNotEmpty) {
        final result = _resultToEnd(getUserData);
        return Response.ok(jsonEncode({...result[0]}));
      } else {
        await db.registerUser(
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            accessToken: accessToken);
        final getUserData = await db.authUser(userId: userId);
        if (getUserData.isNotEmpty) {
          final result = _resultToEnd(getUserData);
          return Response.ok(jsonEncode({...result[0]}));
        } else {
          return Response.notFound('Ошибка регистрации. Что-то пошло не так');
        }
      }
    } catch (e) {
      ls.logError(e);
      return Response(500, body: 'Error during authentication');
    }
  }

  List<Map<String, dynamic>> _resultToListWithDateTime(Result resultData) {
    return resultData.map((row) {
      final resultDataMap = row.toColumnMap();
      resultDataMap['created_at'] =
          resultDataMap['created_at']?.toIso8601String();
      return resultDataMap;
    }).toList();
  }

  List<Map<String, dynamic>> _resultToEnd(
    Result resultData,
  ) {
    return resultData.map((row) {
      return row.toColumnMap();
    }).toList();
  }

  Future<Response> bugReportHandler(Request request) async {
    final userId = request.headers[DbFields.productUSERID]!;
    final data = jsonDecode(await request.readAsString());
    final bugText = data['bug_report'];
    final result = await db.bugReport(userId: userId, description: bugText);
    return result
        ? Response.ok(jsonEncode({'status': 'success'}))
        : Response(415, body: ' Error reporting bug');
  }
}
