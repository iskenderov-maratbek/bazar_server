import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import '../text_constants.dart';
import '../queries.dart';
import ' ../../../auth/gcs_service.dart';
import '../img_service.dart';

class HandlerService {
  final DatabaseQueries db;
  final GoogleCloudService gcs;
  Map<String, dynamic> data = {};
  File? file;
  List<File>? files;
  HandlerService({required this.db, required this.gcs});

  Future<bool> getJsonAndFile(Request request,
      {bool productIdCheck = false}) async {
    data = {};
    file = null;
    if (request.multipart() case var multipart?) {
      await for (final part in multipart.parts) {
        final contentDisposition = part.headers['content-disposition'];
        if (contentDisposition != null &&
            !contentDisposition.contains('filename=')) {
          if (contentDisposition.contains('json_data')) {
            final contentBytes = await part.fold<List<int>>(
                [], (previous, element) => previous..addAll(element));
            final contentString = utf8.decode(contentBytes);
            data = jsonDecode(contentString);
          }
        } else if (contentDisposition != null &&
            contentDisposition.contains('filename=')) {
          final filename = RegExp(r'filename="(.+)"')
              .firstMatch(contentDisposition)
              ?.group(1);
          if (filename == null) {
            return false;
          }
          final directory = Directory('/tmp');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final photo = File('/tmp/$filename');
          final sink = photo.openWrite();
          await part.pipe(sink);
          await sink.close();
          file = await compressAndCropImage(photo);
        }
      }
    } else {
      return false;
    }
    return true;
  }

  Future<bool> getJsonAndFiles(Request request,
      {bool productIdCheck = false}) async {
    data = {};
    files = [];
    if (request.multipart() case var multipart?) {
      await for (final part in multipart.parts) {
        final contentDisposition = part.headers['content-disposition'];
        print(contentDisposition);
        if (contentDisposition != null &&
            !contentDisposition.contains('filename=')) {
          if (contentDisposition.contains('json_data')) {
            final contentBytes = await part.fold<List<int>>(
                [], (previous, element) => previous..addAll(element));
            final contentString = utf8.decode(contentBytes);
            data = jsonDecode(contentString);
          }
        } else if (contentDisposition != null &&
            contentDisposition.contains('filename=')) {
          final filename = RegExp(r'filename="(.+)"')
              .firstMatch(contentDisposition)
              ?.group(1);
          if (filename == null) {
            return false;
          }
          final directory = Directory('/tmp');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final photo = File('/tmp/$filename');
          final sink = photo.openWrite();
          await part.pipe(sink);
          await sink.close();
          files!.add(await compressAndCropImage(photo));
        }
      }
    } else {
      return false;
    }
    return true;
  }

  Future<bool> tokenCheck(token, id, {int? productId}) async {
    if (token == null ||
        id == null ||
        !token.startsWith(DbFields.secretStart)) {
      return false;
    } else {
      final endOfToken = token.replaceAll('${DbFields.secretStart} ', '');
      if (!await db.verifyUserAccess(
          userId: id, token: endOfToken, productId: productId)) {
        return false;
      }
    }
    return true;
  }
}
