import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/features/area/domain/usecases/list_locations_use_case.dart';
import 'package:resiwash/features/preferences/presentation/cubit/preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  // use cases here
  final ListLocationsUseCase listLocationsUseCase;

  PreferencesCubit({required this.listLocationsUseCase})
    : super(PreferencesInitial());

  Future<void> loadPreferences() async {
    emit(PreferencesLoading());
    try {
      // Load preferences logic here

      // Example loaded data
      final isDarkMode = false;
      final languageCode = 'en';
      final temperatureUnit = 'C';
      final currency = 'USD';
      final savedLocations = SavedLocations({});
      final availableLocations = await listLocationsUseCase.call().then(
        (either) => either.fold((l) => <AreaEntity>[], (r) => r),
      );

      emit(
        PreferencesLoaded(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          temperatureUnit: temperatureUnit,
          currency: currency,
          savedLocations: savedLocations,
          availableLocations: availableLocations,
        ),
      );
    } catch (e) {
      emit(PreferencesInitial()); // or some error state
    }
  }
}
