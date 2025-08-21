import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:resiwash/features/area/domain/entities/area_entity.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';
import 'package:resiwash/features/overview/presentation/widgets/location_tree_select.dart';
import 'package:resiwash/features/overview/presentation/widgets/room_overview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomOverviewWrapper extends StatefulWidget {
  final List<String> roomIds;

  RoomOverviewWrapper({required this.roomIds});

  @override
  State<RoomOverviewWrapper> createState() => _RoomOverviewWrapperState();
}

class _RoomOverviewWrapperState extends State<RoomOverviewWrapper> {
  SavedLocations loadedLocations = SavedLocations({});
  @override
  Widget build(BuildContext context) {
    // This widget would typically use the roomIds to fetch and display
    // the overview of each room, possibly using a ListView or GridView.
    return BlocBuilder<OverviewCubit, OverviewState>(
      builder: (context, state) {
        if (state is OverviewLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is OverviewError) {
          return Center(child: Text(state.message));
        } else if (state is OverviewLoaded) {
          // Use the machinesByRoom from the state
          final machinesByRoom = state.machinesByRoom;
          final locations = state.locations;

          // // Filter machines for the provided roomIds
          // final filteredMachines = roomIds
          //     .map((roomId) => machinesByRoom[roomId] ?? [])
          //     .expand((machines) => machines)
          //     .toList();

          return Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10.0,
                children: [
                  Row(
                    children: [
                      Text(
                        "Rooms",
                        style: GoogleFonts.poppinsTextTheme(
                          Theme.of(context).textTheme,
                        ).headlineSmall,
                      ),
                      Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {
                          showChangeRoomSheet(context, locations);
                        },
                        label: Text("Edit"),
                        icon: Icon(Icons.edit),
                      ),
                    ],
                  ),
                  Column(
                    children: loadedLocations.getAllRoomIds().map((roomId) {
                      return RoomOverview(roomId: roomId);
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  void showChangeRoomSheet(BuildContext context, List<AreaEntity> locations) {
    // set the current room ids
    SavedLocations savedLocations = sl<SharedPreferencesService>()
        .getSavedLocations();

    setState(() {
      loadedLocations = savedLocations;
    });

    showModalBottomSheet(
      context: context,

      builder: (context) {
        return SizedBox(
          width: double.infinity,
          height: 400,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Select rooms',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                LocationTreeSelect(
                  areas: locations,
                  selectedLocations: savedLocations,
                  onSelectionChanged: (newSelectedLocations) {
                    setState(() {
                      loadedLocations = newSelectedLocations;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then(
      (result) => {
        // save the selectedRoomIds to SharedPrefs
        sl<SharedPreferencesService>().setSavedLocations(loadedLocations),
      },
    );
  }
}
