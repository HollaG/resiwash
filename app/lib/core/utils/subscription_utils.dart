import 'package:resiwash/features/machine/data/models/machine_model.dart';

class SubscriptionUtils {
  static String getTopicNameForMachine(String machineId) {
    return "machine_$machineId";
  }

  // static String getTopicNameForGroup(String groupKey) {
  //   return "group_$groupKey";
  // }

  static String getTopicNameForGroup(String roomId, MachineType type) {
    return "group_${roomId}_${type.name}";
  }
}
