// lib/core/logging/logger.dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

Logger createLogger() => Logger(
  level: kReleaseMode ? Level.warning : Level.trace,
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 8,
    lineLength: 120,
    dateTimeFormat: DateTimeFormat.onlyTime,
    colors: !kReleaseMode,
    printEmojis: true,
  ),
);

// Export a shared instance if you prefer:
final appLog = createLogger();
