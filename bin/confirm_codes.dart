import 'dart:math';

import 'package:hive/hive.dart';

class ConfirmCodes {
  final Box<dynamic> _box;
  ConfirmCodes(this._box);
  static final _random = Random();

  Future<String> generateCode(String userdata) async {
    DateTime now = DateTime.now();
    var result = List.generate(4, (_) => _random.nextInt(10)).join();
    await _box.put(userdata, [result, now]);
    return result;
  }

  bool checkCode(String userdata) {
    return _box.get(userdata) != null;
  }

  int? canSendCode(String userdata) {
    if (checkCode(userdata)) {
      DateTime now = DateTime.now();
      var timeleft = now.difference(_box.get(userdata)[1]).inSeconds;
      if (timeleft >= 30) {
        return null;
      } else {
        return timeleft;
      }
    }
    return null;
  }
}
