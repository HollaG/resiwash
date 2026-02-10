import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String roomIdsKey = 'roomIds';
  static const String locationKey = 'locations';

  static const String subscribedMachinesKey = 'notif_subscribedMachines';
  static const String subscribedGroupsKey = 'notif_subscribedGroups';
  static const String claimedMachinesKey = 'claimedMachines';

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

  // Get all subscribed machine IDs
  List<String> getSubscribedMachines() {
    return _prefs.getStringList(subscribedMachinesKey) ?? [];
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

  void subscribeToGroups(Set<String> groupKeys) {
    final existingKeys = _prefs.getStringList(subscribedGroupsKey) ?? [];
    final updatedKeys = existingKeys.toSet().union(groupKeys).toList();
    _prefs.setStringList(subscribedGroupsKey, updatedKeys);
  }

  void unsubscribeFromGroups(Set<String> groupKeys) {
    final existingKeys = _prefs.getStringList(subscribedGroupsKey) ?? [];
    final updatedKeys = existingKeys.toSet().difference(groupKeys).toList();
    print("debug updatedKeys after unsubscribe: $updatedKeys");
    _prefs.setStringList(subscribedGroupsKey, updatedKeys);
  }

  bool isSubscribedToGroup(String groupKey) {
    final existingKeys = _prefs.getStringList(subscribedGroupsKey) ?? [];
    return existingKeys.contains(groupKey);
  }

  List<String> getSubscribedGroups() {
    return _prefs.getStringList(subscribedGroupsKey) ?? [];
  }

  // Claim a machine with optional cycle time
  // remmeber to unclaim any other claimed machine the user has
  ClaimedMachineMetadata claimMachine(String machineId, {int cycleTime = 30}) {
    final existingMachinesMetadata = getClaimedMachinesMetadata();

    // Check if already claimed
    final alreadyClaimed = existingMachinesMetadata.any(
      (m) => m.machineId == machineId,
    );

    if (!alreadyClaimed) {
      final claimedMachine = ClaimedMachineMetadata(
        machineId: machineId,
        cycleTime: cycleTime,
      );
      // NOTE: we only allow one claimed machine at a time logically
      // [feature1]
      // existingMachines.add(claimedMachine);
      // existingMachinesMetadata.clear(); // [UPDATE 9 FEB 2026]: Now supports multiple claimed machines.
      existingMachinesMetadata.add(claimedMachine);
      // Encode all claimed machines to JSON strings
      final encodedMachines = existingMachinesMetadata
          .map((m) => m.encode())
          .toList();
      _prefs.setStringList(claimedMachinesKey, encodedMachines);

      return claimedMachine;
    }

    return existingMachinesMetadata.firstWhere((m) => m.machineId == machineId);
  }

  // Unclaim a machine
  void unclaimMachine(String machineId) {
    final existingMachines = getClaimedMachinesMetadata();
    existingMachines.removeWhere((m) => m.machineId == machineId);

    // Encode remaining claimed machines
    final encodedMachines = existingMachines.map((m) => m.encode()).toList();
    _prefs.setStringList(claimedMachinesKey, encodedMachines);
  }

  // Get all claimed machines
  List<ClaimedMachineMetadata> getClaimedMachinesMetadata() {
    final encodedMachines = _prefs.getStringList(claimedMachinesKey) ?? [];
    return encodedMachines
        .map((encoded) => ClaimedMachineMetadata.decode(encoded))
        .toList();
  }

  ClaimedMachineMetadata? getClaimedMachineMetadata(String machineId) {
    final claimedMachines = getClaimedMachinesMetadata();
    try {
      return claimedMachines.firstWhere((m) => m.machineId == machineId);
    } catch (e) {
      return null;
    }
  }

  // Check if a machine is claimed
  bool isMachineClaimed(String machineId) {
    final claimedMachines = getClaimedMachinesMetadata();
    return claimedMachines.any((m) => m.machineId == machineId);
  }

  // Update cycle time for a claimed machine
  void updateClaimedMachineCycleTime(String machineId, int cycleTime) {
    final existingMachines = getClaimedMachinesMetadata();
    final index = existingMachines.indexWhere((m) => m.machineId == machineId);

    if (index != -1) {
      // Remove old and add updated
      existingMachines.removeAt(index);
      existingMachines.insert(
        index,
        ClaimedMachineMetadata(machineId: machineId, cycleTime: cycleTime),
      );

      // Save updated list
      final encodedMachines = existingMachines.map((m) => m.encode()).toList();
      _prefs.setStringList(claimedMachinesKey, encodedMachines);
    }
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
