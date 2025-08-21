import '../datasource/preferences_datasource.dart';
import '../domain/preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesDatasource datasource;

  PreferencesRepositoryImpl(this.datasource);

  @override
  Future<void> setRoomIds(List<String> roomIds) =>
      datasource.setRoomIds(roomIds);

  @override
  List<String> getRoomIds() => datasource.getRoomIds();

  @override
  Future<void> clearRoomIds() => datasource.clearRoomIds();
}
