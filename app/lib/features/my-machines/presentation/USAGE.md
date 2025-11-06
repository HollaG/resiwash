# MyMachinesCubit Usage Guide

## Overview
`MyMachinesCubit` manages user's subscribed machines with full machine data loading from the repository.

## Setup

```dart
BlocProvider(
  create: (context) => MyMachinesCubit(
    sharedPreferencesService: sl<SharedPreferencesService>(),
    notificationService: sl<NotificationService>(),
    listMachinesUseCase: sl<ListMachinesUseCase>(),
  )..loadSubscribedMachines(), // Load full machine data on init
  child: MyMachinesScreen(),
)
```

## Methods

### 1. Load Machine IDs Only (Fast)
```dart
context.read<MyMachinesCubit>().loadSubscribedMachineIds();
```
- Only loads IDs from local storage (synchronous, fast)
- State: `MyMachinesLoaded(subscribedMachineIds: [...], machines: null)`

### 2. Load Full Machine Data (Recommended)
```dart
context.read<MyMachinesCubit>().loadSubscribedMachines();
```
- Loads IDs from local storage
- Fetches full machine entities from API via `ListMachinesUseCase`
- State: `MyMachinesLoaded(subscribedMachineIds: [...], machines: [...])`

### 3. Subscribe to Machine
```dart
await context.read<MyMachinesCubit>().subscribeToMachine('machine-123');
```
- Subscribes to FCM topic
- Saves to local storage
- Updates state with new list

### 4. Unsubscribe from Machine
```dart
await context.read<MyMachinesCubit>().unsubscribeFromMachine('machine-123');
```
- Unsubscribes from FCM topic
- Removes from local storage
- Updates state

### 5. Delete Subscription (Alias)
```dart
await context.read<MyMachinesCubit>().deleteMachineSubscription('machine-123');
```

## UI Integration

### Using BlocBuilder
```dart
BlocBuilder<MyMachinesCubit, MyMachinesState>(
  builder: (context, state) {
    if (state is MyMachinesLoading) {
      return CircularProgressIndicator();
    } else if (state is MyMachinesLoaded) {
      // Access machine IDs
      final ids = state.subscribedMachineIds;
      
      // Access full machine data (if loaded)
      final machines = state.machines;
      
      if (machines == null) {
        // Only IDs loaded, show basic list
        return ListView(
          children: ids.map((id) => Text('Machine: $id')).toList(),
        );
      } else {
        // Full machine data loaded, show rich UI
        return ListView(
          children: machines.map((machine) => 
            MachineRow(machine: machine)
          ).toList(),
        );
      }
    }
    return SizedBox.shrink();
  },
)
```

### Using BlocConsumer (with error handling)
```dart
BlocConsumer<MyMachinesCubit, MyMachinesState>(
  listener: (context, state) {
    if (state is MyMachinesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    // ... same as above
  },
)
```

## State Types

### 1. MyMachinesInitial
Initial state before any data loaded.

### 2. MyMachinesLoading
Loading state when fetching data from repository.

### 3. MyMachinesLoaded
```dart
class MyMachinesLoaded {
  final List<String> subscribedMachineIds;  // Always present
  final List<MachineEntity>? machines;       // Null if only IDs loaded
}
```

### 4. MyMachinesError
```dart
class MyMachinesError {
  final String message;
}
```

### 5. MyMachinesOperationInProgress
Temporary state during subscribe/unsubscribe operations.

## Complete Example

```dart
class MyMachinesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyMachinesCubit(
        sharedPreferencesService: sl<SharedPreferencesService>(),
        notificationService: sl<NotificationService>(),
        listMachinesUseCase: sl<ListMachinesUseCase>(),
      )..loadSubscribedMachines(), // Load full data
      child: Scaffold(
        appBar: AppBar(title: Text('My Machines')),
        body: BlocConsumer<MyMachinesCubit, MyMachinesState>(
          listener: (context, state) {
            if (state is MyMachinesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is MyMachinesLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (state is MyMachinesLoaded) {
              final machines = state.machines;
              
              if (machines == null || machines.isEmpty) {
                return Center(child: Text('No subscribed machines'));
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MyMachinesCubit>().loadSubscribedMachines();
                },
                child: ListView.builder(
                  itemCount: machines.length,
                  itemBuilder: (context, index) {
                    final machine = machines[index];
                    return ListTile(
                      title: Text(machine.name),
                      subtitle: Text(machine.currentStatus.toString()),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          context
                              .read<MyMachinesCubit>()
                              .unsubscribeFromMachine(machine.machineId);
                        },
                      ),
                    );
                  },
                ),
              );
            }
            
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

## Best Practices

1. **Use `loadSubscribedMachines()` on init** - Gets full machine data for rich UI
2. **Use `loadSubscribedMachineIds()` for fast checks** - When you only need IDs
3. **Always check `machines` for null** - It's null if only IDs were loaded
4. **Handle errors with BlocListener** - Show user-friendly error messages
5. **Use RefreshIndicator** - Allow users to manually refresh data
6. **Call `loadSubscribedMachines()` after error** - Automatically retry loading

## Performance Notes

- `loadSubscribedMachineIds()`: Fast (local storage only)
- `loadSubscribedMachines()`: Slower (API call), but provides rich data
- Subscribe/Unsubscribe: Updates both FCM topics AND local storage atomically
