import 'package:get_it/get_it.dart';
import 'package:resiwash/core/injections/area/area_service_locator.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register your services, repositories, and use cases here.
  // Example:
  // serviceLocator.registerLazySingleton<SomeService>(() => SomeServiceImpl());
  sl.registerSingletonAsync<SharedPreferences>(
    () async => await SharedPreferences.getInstance(),
  );
  await sl.allReady();

  setupRoomServiceLocator();
  setupMachineServiceLocator();
  setupAreaServiceLocator();

  sl.registerSingleton<SharedPreferencesService>(
    SharedPreferencesService(sl<SharedPreferences>()),
  );
}
