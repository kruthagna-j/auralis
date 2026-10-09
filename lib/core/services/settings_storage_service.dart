import 'package:hive_ce/hive.dart';

class SettingsStorageService {
  static const String boxName = 'app_settings';

  static Future<Box<dynamic>> getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }
    return Hive.openBox<dynamic>(boxName);
  }
}
