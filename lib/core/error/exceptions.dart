class DomainException implements Exception {
  final String message;
  final Object? originalError;

  DomainException(this.message, [this.originalError]);

  @override
  String toString() => 'DomainException: $message';
}

class DatabaseException extends DomainException {
  DatabaseException(super.message, [super.originalError]);
}

class ValidationException extends DomainException {
  ValidationException(super.message, [super.originalError]);
}
