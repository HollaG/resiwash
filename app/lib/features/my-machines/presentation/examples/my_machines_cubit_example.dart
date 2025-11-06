// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:resiwash/core/injections/machine/machine_service_locator.dart';
// import 'package:resiwash/core/services/notification_service.dart';
// import 'package:resiwash/core/services/shared_preferences_service.dart';
// import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_cubit.dart';
// import 'package:resiwash/features/my-machines/presentation/cubit/my_machines_state.dart';

// /// Example usage of MyMachinesCubit
// ///
// /// This file demonstrates how to:
// /// 1. Set up the cubit with BlocProvider
// /// 2. Load subscribed machines
// /// 3. Subscribe/unsubscribe to machines
// /// 4. Handle different states

// class MyMachinesExample extends StatelessWidget {
//   const MyMachinesExample({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => MyMachinesCubit(
//         sharedPreferencesService: sl<SharedPreferencesService>(),
//         notificationService: sl<NotificationService>(),
//       )..loadSubscribedMachines(), // Load machines on init
//       child: const MyMachinesView(),
//     );
//   }
// }

// class MyMachinesView extends StatelessWidget {
//   const MyMachinesView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('My Machines')),
//       body: BlocConsumer<MyMachinesCubit, MyMachinesState>(
//         listener: (context, state) {
//           // Show error messages
//           if (state is MyMachinesError) {
//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text(state.message)));
//           }
//         },
//         builder: (context, state) {
//           if (state is MyMachinesLoading) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (state is MyMachinesLoaded) {
//             return _buildMachinesList(context, state.subscribedMachineIds);
//           } else if (state is MyMachinesOperationInProgress) {
//             return _buildMachinesList(
//               context,
//               state.subscribedMachineIds,
//               operatingId: state.operatingMachineId,
//             );
//           } else if (state is MyMachinesError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(state.message),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       context.read<MyMachinesCubit>().loadSubscribedMachines();
//                     },
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }
//           return const SizedBox.shrink();
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Example: Subscribe to a machine
//           _showSubscribeDialog(context);
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildMachinesList(
//     BuildContext context,
//     List<String> machineIds, {
//     String? operatingId,
//   }) {
//     if (machineIds.isEmpty) {
//       return const Center(child: Text('No subscribed machines yet'));
//     }

//     return RefreshIndicator(
//       onRefresh: () async {
//         context.read<MyMachinesCubit>().loadSubscribedMachines();
//       },
//       child: ListView.builder(
//         itemCount: machineIds.length,
//         itemBuilder: (context, index) {
//           final machineId = machineIds[index];
//           final isOperating = machineId == operatingId;

//           return ListTile(
//             title: Text('Machine $machineId'),
//             subtitle: isOperating ? const Text('Processing...') : null,
//             trailing: isOperating
//                 ? const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : IconButton(
//                     icon: const Icon(Icons.delete),
//                     onPressed: () {
//                       _showUnsubscribeConfirmation(context, machineId);
//                     },
//                   ),
//           );
//         },
//       ),
//     );
//   }

//   void _showSubscribeDialog(BuildContext context) {
//     final controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Subscribe to Machine'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             labelText: 'Machine ID',
//             hintText: 'Enter machine ID',
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               final machineId = controller.text.trim();
//               if (machineId.isNotEmpty) {
//                 context.read<MyMachinesCubit>().subscribeToMachine(machineId);
//               }
//               Navigator.pop(dialogContext);
//             },
//             child: const Text('Subscribe'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showUnsubscribeConfirmation(BuildContext context, String machineId) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Unsubscribe'),
//         content: Text('Unsubscribe from machine $machineId?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               context.read<MyMachinesCubit>().unsubscribeFromMachine(machineId);
//               Navigator.pop(dialogContext);
//             },
//             child: const Text('Unsubscribe'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Alternative: Using the cubit in an existing widget
// class ExistingWidgetExample extends StatelessWidget {
//   const ExistingWidgetExample({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Subscribe to a machine
//         ElevatedButton(
//           onPressed: () {
//             context.read<MyMachinesCubit>().subscribeToMachine('machine-123');
//           },
//           child: const Text('Subscribe to Machine 123'),
//         ),

//         // Unsubscribe from a machine
//         ElevatedButton(
//           onPressed: () {
//             context.read<MyMachinesCubit>().unsubscribeFromMachine(
//               'machine-123',
//             );
//           },
//           child: const Text('Unsubscribe from Machine 123'),
//         ),

//         // Delete subscription (same as unsubscribe)
//         ElevatedButton(
//           onPressed: () {
//             context.read<MyMachinesCubit>().deleteMachineSubscription(
//               'machine-123',
//             );
//           },
//           child: const Text('Delete Subscription'),
//         ),

//         // Check if subscribed
//         ElevatedButton(
//           onPressed: () {
//             final isSubscribed = context
//                 .read<MyMachinesCubit>()
//                 .isSubscribedToMachine('machine-123');
//             print('Is subscribed: $isSubscribed');
//           },
//           child: const Text('Check if Subscribed'),
//         ),

//         // Get count
//         BlocBuilder<MyMachinesCubit, MyMachinesState>(
//           builder: (context, state) {
//             final count = context
//                 .read<MyMachinesCubit>()
//                 .getSubscribedMachinesCount();
//             return Text('Subscribed to $count machines');
//           },
//         ),
//       ],
//     );
//   }
// }
