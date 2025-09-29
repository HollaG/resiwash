import 'package:equatable/equatable.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';

sealed class PreferencesState extends Equatable {
  const PreferencesState();

  @override
  List<Object?> get props => [];
}

class PreferencesInitial extends PreferencesState {}

class PreferencesLoading extends PreferencesState {}

class PreferencesLoaded extends PreferencesState {
  final bool isDarkMode;
  final String languageCode;
  final String temperatureUnit; // 'C' or 'F'
  final String currency; // e.g., 'USD', 'EUR'
  final SavedLocations savedLocations;
  final List<AreaEntity> availableLocations;

  const PreferencesLoaded({
    required this.isDarkMode,
    required this.languageCode,
    required this.temperatureUnit,
    required this.currency,
    required this.savedLocations,
    required this.availableLocations,
  });

  PreferencesLoaded copyWith({
    bool? isDarkMode,
    String? languageCode,
    String? temperatureUnit,
    String? currency,
    SavedLocations? savedLocations,
  }) {
    return PreferencesLoaded(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      currency: currency ?? this.currency,
      savedLocations: savedLocations ?? this.savedLocations,
      availableLocations: availableLocations,
    );
  }

  @override
  List<Object?> get props => [
    isDarkMode,
    languageCode,
    temperatureUnit,
    currency,
    savedLocations,
  ];
}

class PreferencesChangeLocationsOpen extends PreferencesState {}
