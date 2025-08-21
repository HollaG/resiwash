import 'package:get_it/get_it.dart';
import 'package:resiwash/core/injections/area/area_service_locator.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Register your services, repositories, and use cases here.
  // Example:
  // serviceLocator.registerLazySingleton<SomeService>(() => SomeServiceImpl());

  setupRoomServiceLocator();
  setupMachineServiceLocator();
  setupAreaServiceLocator();

  // register other services
  sl.registerLazySingleton<SharedPreferencesService>(
    () => SharedPreferencesService(sl()),
  );
}
