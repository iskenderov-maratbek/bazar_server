import 'dart:io';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';

class GoogleCloudService {
  final storage.StorageApi storageApi;
  final String bucketName;
  GoogleCloudService._({required this.storageApi, required this.bucketName});

  static Future<GoogleCloudService> init(
      {required String credentialsJson, required String bucketName}) async {
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    final scopes = [storage.StorageApi.devstorageFullControlScope];
    final httpClient = await clientViaServiceAccount(credentials, scopes);
    final storageApi = storage.StorageApi(httpClient);
    return GoogleCloudService._(storageApi: storageApi, bucketName: bucketName);
  }

  Future<String> uploadFile(
      {required File file,
      required String fileName,
      required String folder,
      bool isUserProfilePhoto = false}) async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);
    final uniqueFileName = '$fileName$formattedDate.jpg';
    final media = storage.Media(file.openRead(), file.lengthSync());
    final objectName = '$folder/$uniqueFileName';
    final object = storage.Object()..name = objectName;
    await storageApi.objects
        .insert(object, bucketName, uploadMedia: media)
        .then((_) {
      file.deleteSync();
    });
    return 'https://storage.googleapis.com/products-tez-bazar/$objectName';
  }

  Future<List<String>> uploadFiles({
    required List<File> files,
    required String fileNamePrefix,
    required String folder,
  }) async {
    final List<String> urls = [];
    for (final file in files) {
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);
      final uniqueFileName = '$fileNamePrefix$formattedDate.jpg';
      final media = storage.Media(file.openRead(), file.lengthSync());
      final objectName = '$folder/$uniqueFileName';
      final object = storage.Object()..name = objectName;
      await storageApi.objects
          .insert(object, bucketName, uploadMedia: media)
          .then((_) {
        file.deleteSync();
      });
      final url =
          'https://storage.googleapis.com/products-tez-bazar/$objectName';
      urls.add(url);
    }

    return urls;
  }

  Future<void> deleteFile(
      {required String fileName, required String folder}) async {
    final objectName = '$folder/$fileName.jpg';
    try {
      await storageApi.objects.delete(bucketName, objectName);
    } catch (e) {
      throw Exception('Failed to delete file');
    }
  }

  Future<void> deleteFiles({
    required List<String> fileNames,
    required String folder,
  }) async {
    try {
      for (final fileName in fileNames) {
        final objectName = '$folder/$fileName';
        await storageApi.objects.delete(bucketName, objectName);
      }
    } catch (e) {
      throw Exception('Failed to delete files $e');
    }
  }
}
