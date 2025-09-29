import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/features/area/domain/repository/area_repository.dart';

class ListLocationsUseCase {
  final AreaRepository repository;

  ListLocationsUseCase({required this.repository});

  Future<Either<Failure, List<AreaEntity>>> call({
    List<String>? areaIds,
    List<String>? roomIds,
  }) async {
    return await repository.listLocations(areaIds: areaIds, roomIds: roomIds);
  }
}
