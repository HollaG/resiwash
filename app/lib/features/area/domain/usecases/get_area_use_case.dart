import 'package:fpdart/fpdart.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/features/area/domain/repository/area_repository.dart';

class GetAreaUseCase {
  final AreaRepository repository;

  GetAreaUseCase({required this.repository});

  Future<Either<Failure, AreaEntity>> call({required String areaId}) {
    return repository.getAreaById(areaId: areaId);
  }
}
