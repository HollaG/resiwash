import 'package:get_it/get_it.dart';
import 'package:resiwash/core/services/firebase_notification_service.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/features/my-machines/domain/usecases/my_machines_usecase.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/subscription_cubit.dart';
import 'package:resiwash/features/my-machines/presentation/cubit/claim_cubit.dart';

final GetIt sl = GetIt.instance;

void setupMyMachinesServiceLocator() {
  sl.registerFactory<MyMachinesUseCase>(
    () => MyMachinesUseCase(repository: sl()),
  );

  // note: as MyMachinesCubit is shared THROUGHOUT the app, we will use a Singleton here
  sl.registerSingleton<MyMachinesCubit>(
    MyMachinesCubit(
      myMachinesUseCase: sl<MyMachinesUseCase>(),
      sharedPreferencesService: sl<SharedPreferencesService>(),
      notificationService: sl<FirebaseNotificationService>(),
      listMachinesUseCase: sl<ListMachinesUseCase>(),
    ),
  );

  // Register the new split cubits as singletons (shared throughout the app)
  sl.registerSingleton<SubscriptionCubit>(
    SubscriptionCubit(
      sharedPreferencesService: sl<SharedPreferencesService>(),
      notificationService: sl<FirebaseNotificationService>(),
      listMachinesUseCase: sl<ListMachinesUseCase>(),
    ),
  );

  sl.registerSingleton<ClaimCubit>(
    ClaimCubit(
      sharedPreferencesService: sl<SharedPreferencesService>(),
      notificationService: sl<FirebaseNotificationService>(),
      listMachinesUseCase: sl<ListMachinesUseCase>(),
      myMachinesUseCase: sl<MyMachinesUseCase>(),
      getMachineUseCase: sl<GetMachineUseCase>(),
    ),
  );
}
