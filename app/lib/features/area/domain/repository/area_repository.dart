import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';

abstract interface class AreaRepository {
  Future<Either<Failure, List<AreaEntity>>> listAreas({
    List<String>? areaIds = const [],
  });

  Future<Either<Failure, List<AreaEntity>>> listLocations({
    List<String>? roomIds = const [],
    List<String>? areaIds = const [],
  });
}
