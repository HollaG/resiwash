import 'dart:convert';

class SavedLocations {
  final Map<String, List<String>> locations;

  SavedLocations(this.locations);

  // Serialize to Map for JSON
  Map<String, dynamic> toJson() => locations;

  // Serialize to String for storage
  String encode() => jsonEncode(toJson());

  // Deserialize from String
  static SavedLocations decode(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    final parsed = map.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
    return SavedLocations(parsed);
  }

  // operations
  void addArea(String areaId, List<String> roomIds) {
    locations[areaId] = roomIds;
  }

  void removeArea(String areaId) {
    locations.remove(areaId);
  }

  void addRoom(String areaId, String roomId) {
    if (!locations.containsKey(areaId)) {
      locations[areaId] = [];
    }
    locations[areaId]?.add(roomId);
  }

  void removeRoom(String areaId, String roomId) {
    locations[areaId]?.remove(roomId);
    if (locations[areaId]?.isEmpty ?? true) {
      locations.remove(areaId);
    }
  }

  List<String> getAllRoomIds() {
    return locations.values.expand((roomIds) => roomIds).toList();
  }

  bool isAreaSaved(String areaId) {
    return locations.containsKey(areaId);
  }

  bool isRoomSaved(String areaId, String roomId) {
    return locations[areaId]?.contains(roomId) ?? false;
  }

  int getRoomCount(String areaId) {
    return locations[areaId]?.length ?? 0;
  }
}
