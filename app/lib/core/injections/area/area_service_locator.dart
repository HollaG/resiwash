import 'package:get_it/get_it.dart';
import 'package:resiwash/features/area/data/datasource/area_remote_datasource.dart';
import 'package:resiwash/features/area/data/repository/area_repository_impl.dart';
import 'package:resiwash/features/area/domain/repository/area_repository.dart';
import 'package:resiwash/features/area/domain/usecases/list_locations_use_case.dart';

final GetIt sl = GetIt.instance;

void setupAreaServiceLocator() {
  sl.registerSingleton<AreaRemoteDatasource>(AreaRemoteDatasource());
  sl.registerSingleton<AreaRepository>(
    AreaRepositoryImpl(dataSource: sl<AreaRemoteDatasource>()),
  );
  sl.registerSingleton<ListLocationsUseCase>(
    ListLocationsUseCase(repository: sl<AreaRepository>()),
  );
}
