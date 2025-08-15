import 'package:get_it/get_it.dart';
import 'package:resiwash/core/injections/room/room_service_locator.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Register your services, repositories, and use cases here.
  // Example:
  // serviceLocator.registerLazySingleton<SomeService>(() => SomeServiceImpl());

  setupRoomServiceLocator();
}
