part of oauth2;

/// An exception raised when attempting to use expired OAuth2 credentials.
class ExpirationException implements Exception {
  /// The expired credentials.
  final OAuth2Credentials credentials;

  /// Creates an ExpirationException.
  ExpirationException(this.credentials);

  /// Provides a string description of the ExpirationException.
  String toString() =>
    "OAuth2 credentials have expired and can't be refreshed.";
}
