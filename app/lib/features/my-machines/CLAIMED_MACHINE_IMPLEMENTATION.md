# ClaimedMachine Implementation Summary

## Changes Made

### 1. `ClaimedMachine` Class (`core/utils/claimed_machine.dart`)
Now stores machine ID with optional cycle time:
```dart
ClaimedMachine({
  required String machineId,
  int? cycleTime,  // null by default
})
```

**Features:**
- JSON serialization (`toJson()`, `fromJson()`)
- String encoding/decoding for SharedPreferences storage
- Default `cycleTime` is `null`

---

### 2. `SharedPreferencesService` Updates

#### New Storage Format
**Old:** Stored list of machine ID strings  
**New:** Stores list of JSON-encoded `ClaimedMachine` objects

#### Updated Methods

**`claimMachine(String machineId, {int? cycleTime})`**
- Creates `ClaimedMachine` with optional cycle time (defaults to null)
- Prevents duplicate claims
- Stores as JSON string list

**`unclaimMachine(String machineId)`**
- Removes machine from claimed list
- Updates SharedPreferences

**`getClaimedMachines() → List<ClaimedMachine>`**
- Returns full `ClaimedMachine` objects
- Decodes from JSON strings

**`getClaimedMachineIds() → List<String>`**
- Returns just the IDs (for backward compatibility)
- Used by state to track which machines are claimed

**`isMachineClaimed(String machineId) → bool`**
- Quick check if machine is claimed

**`updateClaimedMachineCycleTime(String machineId, int? cycleTime)`**
- Update cycle time without unclaiming/reclaiming
- Preserves machine in claimed list

---

### 3. `MyMachinesCubit` Updates

**`claimMachine(String machineId, {int? cycleTime})`**
- Now accepts optional `cycleTime` parameter
- Defaults to `null` if not provided
- Updates state after claiming

**`unclaimMachine(String machineId)`**
- No changes to signature
- Works with new ClaimedMachine storage

**`updateClaimedMachineCycleTime(String machineId, int? cycleTime)`**
- New method to update cycle time
- Doesn't trigger state rebuild (IDs don't change)

**State Loading:**
- Uses `getClaimedMachineIds()` for state (only IDs needed)
- Can access full `ClaimedMachine` objects when needed via service

---

## Usage Examples

### Basic Claim (no cycle time)
```dart
// Cycle time defaults to null
context.read<MyMachinesCubit>().claimMachine('machine-123');

// Stored as: ClaimedMachine(machineId: 'machine-123', cycleTime: null)
```

### Claim with Cycle Time
```dart
context.read<MyMachinesCubit>().claimMachine(
  'machine-123',
  cycleTime: 45, // 45 minutes
);

// Stored as: ClaimedMachine(machineId: 'machine-123', cycleTime: 45)
```

### Update Cycle Time
```dart
// User initially claimed without knowing cycle time
context.read<MyMachinesCubit>().claimMachine('machine-123');

// Later, user sets the cycle time
context.read<MyMachinesCubit>().updateClaimedMachineCycleTime(
  'machine-123',
  60, // 60 minutes
);
```

### Access Full ClaimedMachine Objects
```dart
final sharedPref = sl<SharedPreferencesService>();
final claimedMachines = sharedPref.getClaimedMachines();

for (final claimed in claimedMachines) {
  print('Machine ${claimed.machineId}');
  if (claimed.cycleTime != null) {
    print('  Cycle time: ${claimed.cycleTime} minutes');
  } else {
    print('  Cycle time: Not set');
  }
}
```

### Check if Machine is Claimed
```dart
final sharedPref = sl<SharedPreferencesService>();
final isClaimed = sharedPref.isMachineClaimed('machine-123');
```

---

## Migration Notes

### Breaking Changes
⚠️ **Existing claimed machines data will be lost** if users upgrade from old format.

### Migration Strategy (if needed)
If you need to migrate existing data:

1. Read old format (string list)
2. Convert to `ClaimedMachine` objects with `cycleTime: null`
3. Save in new format

```dart
// Migration code (run once on app upgrade)
void migrateClaimedMachines(SharedPreferences prefs) {
  final oldKey = 'claimedMachines';
  final oldIds = prefs.getStringList(oldKey) ?? [];
  
  if (oldIds.isNotEmpty) {
    final machines = oldIds.map((id) => 
      ClaimedMachine(machineId: id, cycleTime: null)
    ).toList();
    
    final encoded = machines.map((m) => m.encode()).toList();
    prefs.setStringList(oldKey, encoded);
  }
}
```

---

## Benefits

✅ **Richer data storage** - Can store cycle time alongside machine ID  
✅ **Future extensibility** - Easy to add more fields (e.g., startTime, notes)  
✅ **Type safety** - Strongly typed objects instead of just strings  
✅ **Backward compatible** - `getClaimedMachineIds()` works like before  
✅ **Flexible** - Cycle time is optional (null by default)
