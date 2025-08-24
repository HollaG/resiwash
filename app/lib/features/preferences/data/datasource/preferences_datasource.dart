import 'package:shared_preferences/shared_preferences.dart';

class PreferencesDatasource {
  final SharedPreferences _prefs;

  PreferencesDatasource(this._prefs);

  static const String roomIdsKey = 'roomIds';

  Future<void> setRoomIds(List<String> roomIds) async {
    await _prefs.setStringList(roomIdsKey, roomIds);
  }

  List<String> getRoomIds() {
    return _prefs.getStringList(roomIdsKey) ?? [];
  }

  Future<void> clearRoomIds() async {
    await _prefs.remove(roomIdsKey);
  }
}
