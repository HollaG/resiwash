import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/features/area/domain/usecases/get_area_use_case.dart';
import 'package:resiwash/features/area/presentation/cubit/area_detail_state.dart';

class AreaDetailCubit extends Cubit<AreaDetailState> {
  GetAreaUseCase getAreaUsecase;

  AreaDetailCubit({required this.getAreaUsecase}) : super(AreaDetailInitial());

  Future<void> load({required String areaId}) async {
    emit(AreaDetailLoading());
    final area = await getAreaUsecase.call(areaId: areaId);

    area.fold(
      (err) => emit(AreaDetailError("Failed to load area $areaId")),
      (area) => emit(AreaDetailLoaded(area: area)),
    );
  }
}
