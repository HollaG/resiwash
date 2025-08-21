import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String roomIdsKey = 'roomIds';

  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  // Save a list of room IDs
  Future<void> setRoomIds(List<String> roomIds) async {
    await _prefs.setStringList(roomIdsKey, roomIds);
  }

  // Retrieve the list of room IDs
  List<String> getRoomIds() {
    return _prefs.getStringList(roomIdsKey) ?? [];
  }

  // Optionally, clear the room IDs
  Future<void> clearRoomIds() async {
    await _prefs.remove(roomIdsKey);
  }
}
