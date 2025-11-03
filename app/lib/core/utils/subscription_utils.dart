class SubscriptionUtils {
  static String getTopicNameForMachine(String machineId) {
    return "machine_$machineId";
  }
}
