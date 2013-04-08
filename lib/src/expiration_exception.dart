library expiration_exception;

import 'dart:io';

import 'oauth_credentials.dart';

/// An exception raised when attempting to use expired OAuth2 credentials.
class ExpirationException implements Exception {
  /// The expired credentials.
  final OAuthCredentials credentials;

  /// Creates an ExpirationException.
  ExpirationException(this.credentials);

  /// Provides a string description of the ExpirationException.
  String toString() =>
    "OAuth2 credentials have expired and can't be refreshed.";
}
