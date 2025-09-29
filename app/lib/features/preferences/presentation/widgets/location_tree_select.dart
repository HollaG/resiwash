import 'package:flutter/material.dart';
import 'package:resiwash/features/room/domain/entities/room_entity.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';

class LocationTreeSelect extends StatefulWidget {
  final List<AreaEntity> areas;
  final SavedLocations selectedLocations;
  final ValueChanged<SavedLocations> onSelectionChanged;

  const LocationTreeSelect({
    super.key,
    required this.areas,
    required this.selectedLocations,
    required this.onSelectionChanged,
  });

  @override
  State<LocationTreeSelect> createState() => _LocationTreeSelectState();
}

class _LocationTreeSelectState extends State<LocationTreeSelect> {
  late SavedLocations _selectedLocations;

  @override
  void initState() {
    super.initState();
    _selectedLocations = widget.selectedLocations;
  }

  void _onRoomChanged(AreaEntity area, RoomEntity room, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedLocations.addRoom(area.areaId, room.roomId);
      } else {
        _selectedLocations.removeRoom(area.areaId, room.roomId);
      }
      widget.onSelectionChanged(_selectedLocations);
    });
  }

  void _onAreaChanged(AreaEntity area, bool? selected) {
    setState(() {
      if (selected == true) {
        List<String> roomIds =
            area.rooms?.map((room) => room.roomId).toList() ?? [];
        _selectedLocations.addArea(area.areaId, roomIds);
      } else {
        _selectedLocations.removeArea(area.areaId);
      }
      widget.onSelectionChanged(_selectedLocations);
    });
  }

  CheckboxState _getAreaCheckboxState(AreaEntity area) {
    final total = area.rooms?.length ?? 0;
    final selected = _selectedLocations.getRoomCount(area.areaId);
    if (selected == 0) return CheckboxState.unchecked;
    if (selected == total) return CheckboxState.checked;
    return CheckboxState.indeterminate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // shrinkWrap: true,
      children: widget.areas.map((area) {
        final areaState = _getAreaCheckboxState(area);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: areaState == CheckboxState.checked
                      ? true
                      : areaState == CheckboxState.unchecked
                      ? false
                      : null,
                  tristate: true,
                  onChanged: (val) => _onAreaChanged(area, val),
                ),
                Text(area.name, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Column(
                children: (area.rooms != null && area.rooms!.isNotEmpty)
                    ? area.rooms!.map((room) {
                        return Row(
                          children: [
                            Checkbox(
                              value: _selectedLocations.isRoomSaved(
                                area.areaId,
                                room.roomId,
                              ),
                              onChanged: (val) =>
                                  _onRoomChanged(area, room, val),
                            ),
                            Text(room.name),
                          ],
                        );
                      }).toList()
                    : [Text("No rooms available in this area")],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

enum CheckboxState { checked, unchecked, indeterminate }
