import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String roomIdsKey = 'roomIds';
  static const String locationKey = 'locations';

  static const String subscribedMachinesKey = 'notif_subscribedMachines';

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

  // subscribe to a set of machineIds, adding on to existing subscriptions
  void subscribeToMachines(Set<String> machineIds) {
    final existingIds = _prefs.getStringList(subscribedMachinesKey) ?? [];
    final updatedIds = existingIds.toSet().union(machineIds).toList();
    _prefs.setStringList(subscribedMachinesKey, updatedIds);
  }

  // helper to subscribe to a single machineId
  void subscribeToMachine(String machineId) {
    subscribeToMachines({machineId});
  }

  bool isSubscribedToMachine(String machineId) {
    final existingIds = _prefs.getStringList(subscribedMachinesKey) ?? [];
    return existingIds.contains(machineId);
  }

  void unsubscribeFromMachines(Set<String> machineIds) {
    final existingIds = _prefs.getStringList(subscribedMachinesKey) ?? [];
    final updatedIds = existingIds.toSet().difference(machineIds).toList();
    _prefs.setStringList(subscribedMachinesKey, updatedIds);
  }

  // helper to unsubscribe from a single machineId
  void unsubscribeFromMachine(String machineId) {
    unsubscribeFromMachines({machineId});
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
