import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

Future<File> compressAndCropImage(File file) async {
  final now = DateTime.now();
  final formatter = DateFormat('yyyyMMdd_HHmmss');
  await Future.delayed(Duration(milliseconds: 250));
  final formattedDate = formatter.format(now);
  final imageBytes = file.readAsBytesSync();
  img.Image image =
      img.decodeImage(imageBytes)!; // Проверка размера изображения
  if (image.width > 800 || image.height > 800) {
    // Сжатие изображения до ширины 800 пикселей
    image = img.copyResize(image, width: 800);
    // Если высота больше ширины, обрезаем изображение
    if (image.height > image.width) {
      final cropSize = image.width;
      final yOffset = (image.height - cropSize) ~/ 2;
      image = img.copyCrop(image,
          x: 0, y: yOffset, width: cropSize, height: cropSize);
    }
  } // Сохранение сжатого и/или обрезанного изображения в файл с хорошим качеством
  final outputFile =
      File(file.path.replaceAll('.jpg', '-${formattedDate}_compressed.jpg'));
  outputFile
      .writeAsBytesSync(img.encodeJpg(image, quality: 90)); // Качество 90%

  return outputFile;
}
