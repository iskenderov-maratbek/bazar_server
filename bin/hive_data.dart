import 'package:hive/hive.dart';

class HiveData {
  late Box box;

  HiveData({required this.box});

  Future<void> setData(String key, String data) async {
    await box.put(key, data);
  }

  Future<String?> getData(key) async {
    var version = box.get(key);
    return version;
  }

  Future<void> closeBox() async {
    await box.close();
  }
}
