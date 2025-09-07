import 'package:get_it/get_it.dart';
import 'package:resiwash/features/machine/data/datasource/machine_remote_datasource.dart';
import 'package:resiwash/features/machine/data/repository/machine_repository_impl.dart';
import 'package:resiwash/features/machine/domain/repository/machine_repository.dart';
import 'package:resiwash/features/machine/domain/usecases/get_machine_usecase.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';

final GetIt sl = GetIt.instance;

void setupMachineServiceLocator() {
  sl.registerSingleton<MachineRemoteDatasource>(
    MachineRemoteDatasource(),
    // instanceName: 'machineRemoteDatasource',
  );
  sl.registerSingleton<MachineRepository>(
    MachineRepositoryImpl(dataSource: sl<MachineRemoteDatasource>()),
  );
  sl.registerSingleton<ListMachinesUseCase>(
    ListMachinesUseCase(repository: sl<MachineRepository>()),
  );

  sl.registerSingleton<GetMachineUseCase>(
    GetMachineUseCase(repository: sl<MachineRepository>()),
  );

  // sl.registerSingleton<MachineCubit>(
  //   MachineCubit(getMachinesUseCase: sl(instanceName: 'getMachinesUseCase')),
  //   instanceName: 'machineCubit',
  // );
}
