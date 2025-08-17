import 'package:get_it/get_it.dart';
import 'package:resiwash/core/shared/room/data/datasource/room_remote_datasource.dart';
import 'package:resiwash/core/shared/room/data/repository/room_repository_impl.dart';
import 'package:resiwash/core/shared/room/domain/repositories/room_repository.dart';
import 'package:resiwash/core/shared/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/core/shared/room/presentation/cubit/room_cubit.dart';

final GetIt sl = GetIt.instance;

void setupRoomServiceLocator() {
  sl.registerSingleton<RoomRemoteDatasource>(
    RoomRemoteDatasource(),
    instanceName: 'roomRemoteDatasource',
  );
  sl.registerSingleton<RoomRepository>(
    RoomRepositoryImpl(dataSource: sl(instanceName: 'roomRemoteDatasource')),
    instanceName: 'roomRepositoryImpl',
  );
  sl.registerSingleton<GetRoomUsecase>(
    GetRoomUsecase(repository: sl(instanceName: 'roomRepositoryImpl')),
    instanceName: 'getRoomUsecase',
  );
  sl.registerSingleton<RoomCubit>(
    RoomCubit(getRoomUsecase: sl(instanceName: 'getRoomUsecase')),
    instanceName: 'roomCubit',
  );
}
