import 'package:get_it/get_it.dart';
import 'package:resiwash/features/room/data/datasource/room_remote_datasource.dart';
import 'package:resiwash/features/room/data/repository/room_repository_impl.dart';
import 'package:resiwash/features/room/domain/repositories/room_repository.dart';
import 'package:resiwash/features/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';

final GetIt sl = GetIt.instance;

void setupRoomServiceLocator() {
  sl.registerSingleton<RoomRemoteDatasource>(RoomRemoteDatasource());
  sl.registerSingleton<RoomRepository>(
    RoomRepositoryImpl(dataSource: sl<RoomRemoteDatasource>()),
  );
  sl.registerSingleton<GetRoomUsecase>(GetRoomUsecase(repository: sl()));

  sl.registerSingleton<RoomDetailCubit>(RoomDetailCubit(getRoomUsecase: sl()));
}
