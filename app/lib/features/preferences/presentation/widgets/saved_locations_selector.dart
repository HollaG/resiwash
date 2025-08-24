import 'package:flutter/material.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/features/preferences/presentation/widgets/location_tree_select.dart';

class SavedLocationsSelector extends StatelessWidget {
  final List<AreaEntity> areas;
  final SavedLocations selectedLocations;
  final ValueChanged<SavedLocations> onSelectionChanged;

  const SavedLocationsSelector({
    Key? key,
    required this.areas,
    required this.selectedLocations,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LocationTreeSelect(
      areas: areas,
      selectedLocations: selectedLocations,
      onSelectionChanged: onSelectionChanged,
    );
  }
}
