import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/core/injections/service_locator.dart';
import 'package:resiwash/core/shared/mixins/error_handler_mixin.dart';
import 'package:resiwash/features/area/domain/usecases/get_area_use_case.dart';
import 'package:resiwash/features/area/presentation/cubit/area_detail_cubit.dart';
import 'package:resiwash/features/area/presentation/cubit/area_detail_state.dart';
import 'package:resiwash/features/room/domain/usecase/get_room_usecase.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_cubit.dart';
import 'package:resiwash/features/room/presentation/cubit/room_detail_state.dart';

class MachineListAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<String> roomIds;
  final List<String> areaIds;
  final String? title;
  final String? count;

  const MachineListAppBar({
    super.key,
    required this.roomIds,
    required this.areaIds,
    this.title,
    this.count,
  });

  @override
  State<MachineListAppBar> createState() => _MachineListAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MachineListAppBarState extends State<MachineListAppBar>
    with ErrorHandlerMixin {
  @override
  Widget build(BuildContext context) {
    String name = "Machines (${widget.count})";

    if (widget.title != null) {
      return AppBarComponent(
        actions: [],
        title: "${widget.title} (${widget.count})",
      );
    } else {
      return AppBarComponent(actions: [], title: name);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return MultiBlocProvider(
  //     providers: [
  //       if (widget.title != null && widget.roomIds.length == 1)
  //         BlocProvider<RoomDetailCubit>(
  //           create: (context) =>
  //               RoomDetailCubit(getRoomUsecase: sl<GetRoomUsecase>())
  //                 ..load(roomId: widget.roomIds.first),
  //         ),

  //       if (widget.title != null && widget.areaIds.length == 1)
  //         BlocProvider<AreaDetailCubit>(
  //           create: (context) =>
  //               AreaDetailCubit(getAreaUsecase: sl<GetAreaUseCase>())
  //                 ..load(areaId: widget.areaIds.first),
  //         ),
  //     ],
  //     child: MultiBlocListener(
  //       listeners: [
  //         if (widget.areaIds.length == 1)
  //           BlocListener<AreaDetailCubit, AreaDetailState>(
  //             listener: (context, state) {
  //               if (state is AreaDetailError) {
  //                 showErrorMessage(state.message, onRetry: () {});
  //               }

  //               if (state is AreaDetailLoaded) {
  //                 setState(() {
  //                   name = state.area.name;
  //                 });
  //               }
  //             },
  //           ),
  //         if (widget.roomIds.length == 1)
  //           BlocListener<RoomDetailCubit, RoomDetailState>(
  //             listener: (context, state) {
  //               if (state is RoomDetailError) {
  //                 showErrorMessage(state.message, onRetry: () {});
  //               }

  //               if (state is RoomDetailLoaded) {
  //                 setState(() {
  //                   name = state.room.name;
  //                 });
  //               }
  //             },
  //           ),
  //       ],
  //       child: AppBarComponent(actions: [], title: name),
  //     ),
  //   );
  // }
}
