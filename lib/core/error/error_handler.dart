import 'package:flutter/foundation.dart';
import 'exceptions.dart';

class ErrorHandler {
  static void logError(Object error, [StackTrace? stackTrace]) {
    debugPrint('ErrorHandler caught: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static String getUserFriendlyMessage(Object error) {
    if (error is DomainException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
