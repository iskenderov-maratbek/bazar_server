import 'package:shelf/shelf.dart';
import 'text_constants.dart';

import 'hive_data.dart';

class HandlerVersion {
  final HiveData hiveData;
  late final String version;
  HandlerVersion({required this.hiveData});

  gethomeVersionHandler(Request request) async {
    final homeVersion =
        await hiveData.getData(DbFields.homeVersionKey) ?? '0.0.0';
    if (request.headers[DbFields.homeVersionKey] == null) {
      return Response.notFound('Version not found');
    }
    final clientVersion = request.headers[DbFields.homeVersionKey];
    final List<int> oldVersion =
        clientVersion!.split('.').map(int.parse).toList();
    final List<int> newVersion = homeVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < newVersion.length; i++) {
      if (oldVersion.length <= i) {
        return Response.ok(null);
      }
      if (newVersion[i] > oldVersion[i]) {
        return Response(
          201,
          body: null,
          headers: {DbFields.homeVersionKey: homeVersion},
        );
      }
    }

    return Response.ok(null);
  }

  Future<Response> getUserProductVersionHandler(Request request) async {
    final userProductVersion =
        await hiveData.getData(DbFields.userProductVersionKey) ?? '0.0.0';
    if (request.headers[DbFields.userProductVersionKey] == null) {
      return Response.notFound('Version not found');
    }
    final clientVersion = request.headers[DbFields.userProductVersionKey];
    final List<int> oldVersion =
        clientVersion!.split('.').map(int.parse).toList();
    final List<int> newVersion =
        userProductVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < newVersion.length; i++) {
      if (oldVersion.length <= i) {
        return Response.ok(null);
      }
      if (newVersion[i] > oldVersion[i]) {
        return Response(
          201,
          body: null,
          headers: {DbFields.userProductVersionKey: userProductVersion},
        );
      }
    }
    return Response.ok(null);
  }
}
