import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/area/data/datasource/area_remote_datasource.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/features/area/domain/repository/area_repository.dart';

class AreaRepositoryImpl implements AreaRepository {
  AreaRemoteDatasource dataSource;

  AreaRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<AreaEntity>>> listAreas({
    List<String>? areaIds = const [],
  }) async {
    try {
      final areas = await dataSource.listAreas(areaIds: areaIds);
      return Right(areas);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      return Left(Failure());
    }
  }

  @override
  Future<Either<Failure, List<AreaEntity>>> listLocations({
    List<String>? areaIds = const [],
    List<String>? roomIds = const [],
  }) async {
    try {
      final areas = await dataSource.listLocations(
        areaIds: areaIds,
        roomIds: roomIds,
      );

      print("after datasource");
      return Right(areas);
    } on Failure catch (e) {
      return Left(Failure(message: e.message));
    } catch (e) {
      return Left(Failure());
    }
  }
}
