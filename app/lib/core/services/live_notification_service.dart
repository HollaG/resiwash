import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:live_activities/live_activities.dart';
import 'package:resiwash/core/logging/logger.dart';
import 'package:resiwash/core/utils/claimed_machine.dart';
import 'package:resiwash/features/machine/domain/entities/machine_entity.dart';

class LiveNotificationService {
  final LiveActivities _liveActivitiesPlugin = LiveActivities();

  LiveNotificationService();

  Future<void> initialize() async {
    // Live Activities only supported on iOS and Android
    if (kIsWeb) {
      appLog.d(
        "[LiveNotificationService] Skipping initialization on web platform",
      );
      return;
    }

    if (!Platform.isIOS && !Platform.isAndroid) {
      appLog.d(
        "[LiveNotificationService] Skipping initialization on unsupported platform",
      );
      return;
    }

    await _liveActivitiesPlugin.init(appGroupId: "group.com.resiwash.app");
  }

  Future<bool> checkActivityEnabled() async {
    // Live Activities only supported on iOS and Android
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return false;
    }

    bool isActivitiesSupported = await _liveActivitiesPlugin
        .areActivitiesSupported();
    bool isActivitiesEnabled = await _liveActivitiesPlugin
        .areActivitiesEnabled();
    appLog.d(
      "[LiveNotificationService] Activities supported: $isActivitiesSupported, enabled: $isActivitiesEnabled",
    );
    return isActivitiesSupported && isActivitiesEnabled;
  }

  Future<void> startActivity({
    required MachineEntity machine,
    ClaimedMachineMetadata? metadata,
  }) async {
    bool canStart = await checkActivityEnabled();
    if (!canStart) {
      appLog.w(
        "[LiveNotificationService] Cannot start activity, Live Activities not supported or enabled.",
      );
      return;
    }

    appLog.i(
      "[LiveNotificationService] Starting live activity for machine: ${machine.machineId}",
    );

    final Map<String, dynamic> activityModel = {
      "title": "Using ${machine.name}",
      "subtext":
          "${machine.room?.name} @ ${machine.room?.area?.shortName ?? machine.room?.area?.name}",
    };

    _liveActivitiesPlugin.createActivity(machine.machineId, activityModel);
    // TODO: populate activityModel with machine and metadata
    // Example: activityModel['machineId'] = machine.id;
    // Call to the plugin omitted here until the activity data is prepared.
  }
}
