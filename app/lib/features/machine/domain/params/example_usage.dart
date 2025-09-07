// Example usage of ListMachinesParams as a props object in Clean Architecture

import 'package:resiwash/features/machine/domain/params/list_machines_params.dart';
import 'package:resiwash/features/machine/presentation/cubit/machine_list_cubit.dart';

void exampleUsage() {
  // Create params objects for different scenarios

  // 1. Load machines by room IDs
  final roomParams = ListMachinesParams(
    roomIds: ['room1', 'room2'],
    extra: true,
  );

  // 2. Load machines by area IDs
  final areaParams = ListMachinesParams(areaIds: ['area1', 'area2'], min: true);

  // 3. Load specific machines
  final machineParams = ListMachinesParams(
    machineIds: ['machine1', 'machine2'],
    extra: false,
  );

  // 4. Complex query with multiple filters
  final complexParams = ListMachinesParams(
    roomIds: ['room1'],
    areaIds: ['area1'],
    min: false,
    extra: true,
  );

  // 5. Empty params for all machines
  final allMachinesParams = ListMachinesParams();

  // Usage with cubit (example - you'd get this from dependency injection)
  // final cubit = MachineListCubit(listMachinesUseCase: useCase);

  // Now you can use the params object directly:
  // cubit.load(
  //   roomIds: roomParams.roomIds,
  //   areaIds: roomParams.areaIds,
  //   extra: roomParams.extra,
  // );

  // Or create modified versions
  final modifiedParams = roomParams.copyWith(extra: false, min: true);

  // Convert to JSON for API calls (handled internally by datasource)
  final jsonData = complexParams.toJson();
  print('Query parameters: $jsonData');

  // Compare params objects
  final sameParams = ListMachinesParams(
    roomIds: ['room1', 'room2'],
    extra: true,
  );
  print('Params are equal: ${roomParams == sameParams}'); // true
}

// Clean Architecture Flow:
// 1. UI creates ListMachinesParams
// 2. Cubit receives params and passes to UseCase
// 3. UseCase passes params to Repository
// 4. Repository passes params to DataSource
// 5. DataSource converts to query parameters via toJson()
