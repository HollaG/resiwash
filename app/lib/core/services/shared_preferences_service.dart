import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String roomIdsKey = 'roomIds';
  static const String locationKey = 'locations';
  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  Future<void> setSavedLocations(SavedLocations locationIds) async {
    await _prefs.setString(locationKey, locationIds.encode());
  }

  SavedLocations getSavedLocations() {
    final locationsString = _prefs.getString(locationKey);
    if (locationsString != null) {
      return SavedLocations.decode(locationsString);
    }
    return SavedLocations({});
  }

  // // Save a list of room IDs
  // Future<void> setRoomIds(Set<String> roomIds) async {
  //   await _prefs.setStringList(roomIdsKey, roomIds);
  // }

  // // Retrieve the list of room IDs
  // List<String> getRoomIds() {
  //   return _prefs.getStringList(roomIdsKey) ?? [];
  // }

  // // Optionally, clear the room IDs
  // Future<void> clearRoomIds() async {
  //   await _prefs.remove(roomIdsKey);
  // }
}
