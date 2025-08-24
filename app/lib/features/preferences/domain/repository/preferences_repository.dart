abstract class PreferencesRepository {
  Future<void> setRoomIds(List<String> roomIds);
  List<String> getRoomIds();
  Future<void> clearRoomIds();
}
