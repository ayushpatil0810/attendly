/// Base failure class for domain and application errors
sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

class DuplicateSessionFailure extends AppFailure {
  const DuplicateSessionFailure(super.message, {this.existingSessionId});
  final int? existingSessionId;
}
