import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/services/shared_preferences_service.dart';
import 'package:resiwash/core/utils/saved_locations.dart';
import 'package:resiwash/features/machine/domain/usecases/list_machines_usecase.dart';
import 'package:resiwash/core/shared/mixins/error_handler_mixin.dart';
import 'package:resiwash/features/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_state.dart';
import 'package:resiwash/features/area/domain/usecases/list_locations_use_case.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_cubit.dart';
import 'package:resiwash/features/overview/presentation/cubit/overview_state.dart';
import 'package:resiwash/features/overview/presentation/widgets/homeHeader.dart';
import 'package:resiwash/features/overview/presentation/widgets/room_overview_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ErrorHandlerMixin {
  final getRoomUsecase = sl<GetRoomUsecase>();
  SavedLocations loadedLocations = SavedLocations({});

  // on init,
  @override
  void initState() {
    super.initState();
    // Load saved locations
    // set the current room ids
    SavedLocations savedLocations = sl<SharedPreferencesService>()
        .getSavedLocations();

    setState(() {
      loadedLocations = savedLocations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OverviewCubit(
        listMachinesUseCase: sl<ListMachinesUseCase>(),
        listLocationsUseCase: sl<ListLocationsUseCase>(),
      )..load(roomIds: loadedLocations.getAllRoomIds()),

      child: BlocConsumer<OverviewCubit, OverviewState>(
        listener: (context, state) {
          // Listen for error states and show toast
          if (state is OverviewError) {
            showErrorMessage(
              state.message,
              onRetry: () {
                context.read<OverviewCubit>().load(
                  roomIds: loadedLocations.getAllRoomIds(),
                );
              },
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            // appBar: AppBarComponent(actions: [], title: "ResiWash"),
            body: RefreshIndicator(
              onRefresh: () {
                return Future.delayed(Duration(seconds: 1), () {});
                // return context
                //     .read<OverviewCubit>()
                //     .refresh(roomIds: loadedLocations.getAllRoomIds());
              },
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(username: "Marcus"),
                    RoomOverviewWrapper(roomIds: []),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
