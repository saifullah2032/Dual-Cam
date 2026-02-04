import 'package:logger/logger.dart';

/// Global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf,
}

/// Application logging utility
class AppLogger {
  static final _logger = logger;

  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    switch (level) {
      case LogLevel.verbose:
        _logger.t(message);
      case LogLevel.debug:
        _logger.d(message);
      case LogLevel.info:
        _logger.i(message);
      case LogLevel.warning:
        _logger.w(message);
      case LogLevel.error:
        _logger.e(message, error: error, stackTrace: stackTrace);
      case LogLevel.wtf:
        _logger.wtf(message, error: error, stackTrace: stackTrace);
    }
  }

  static void verbose(String message) => log(message, level: LogLevel.verbose);
  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.wtf, error: error, stackTrace: stackTrace);
}
