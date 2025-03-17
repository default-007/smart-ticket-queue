// lib/utils/logger.dart
import 'package:flutter/foundation.dart';

/// Log levels enum
enum Level {
  debug,
  info,
  warning,
  error,
}

/// A simple logger utility for the Smart Ticketing application.
/// Provides methods for logging messages with different severity levels.
class Logger {
  // Singleton pattern
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  static const String _tag = 'SmartTicketing';

  /// Current minimum log level
  Level _currentLevel = kDebugMode ? Level.debug : Level.info;

  /// Sets the minimum log level
  void setLevel(Level level) {
    _currentLevel = level;
  }

  /// Log a debug message
  void debug(String message) {
    if (_currentLevel.index <= Level.debug.index) {
      _log('DEBUG', message);
    }
  }

  /// Log an info message
  void info(String message) {
    if (_currentLevel.index <= Level.info.index) {
      _log('INFO', message);
    }
  }

  /// Log a warning message
  void warn(String message) {
    if (_currentLevel.index <= Level.warning.index) {
      _log('WARNING', message);
    }
  }

  /// Log an error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_currentLevel.index <= Level.error.index) {
      _log('ERROR', message);
      if (error != null) {
        debugPrint('$_tag ERROR: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_tag STACK: $stackTrace');
      }
    }
  }

  /// Internal log method
  void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('$_tag [$timestamp] $level: $message');
  }
}

/// Global logger instance for easy access
final logger = Logger();
