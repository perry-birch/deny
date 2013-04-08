library oauth_credentials;

import 'dart:json' as JSON;
import 'dart:uri';

/// Credentials that prove that a client is allowed to access a resource on the
/// resource owner's behalf. These credentials are long-lasting and can be
/// safely persisted across multiple runs of the program.
///
/// Many authorization servers will attach an expiration date to a set of
/// credentials, along with a token that can be used to refresh the credentials
/// once they've expired. The [Client] will automatically refresh its
/// credentials when necessary. It's also possible to explicitly refresh them
/// via [Client.refreshCredentials] or [Credentials.refresh].
///
/// Note that a given set of credentials can only be refreshed once, so be sure
/// to save the refreshed credentials for future use.
class OAuthCredentials {
/// The token that is sent to the resource server to prove the authorization
  /// of a client.
  final String accessToken;

  /// The token that is sent to the authorization server to refresh the
  /// credentials. This is optional.
  final String refreshToken;

  /// The URL of the authorization server endpoint that's used to refresh the
  /// credentials. This is optional.
  final Uri tokenEndpoint;

  /// The specific permissions being requested from the authorization server.
  /// The scope strings are specific to the authorization server and may be
  /// found in its documentation.
  final List<String> scopes;

  /// The date at which these credentials will expire. This is likely to be a
  /// few seconds earlier than the server's idea of the expiration date.
  final DateTime expiration;

  /// Whether or not these credentials have expired. Note that it's possible the
  /// credentials will expire shortly after this is called. However, since the
  /// client's expiration date is kept a few seconds earlier than the server's,
  /// there should be enough leeway to rely on this.
  bool get isExpired => expiration != null &&
      new DateTime.now().isAfter(expiration);

  /// Whether it's possible to refresh these credentials.
  bool get canRefresh => refreshToken != null && tokenEndpoint != null;

  const OAuthCredentials._(
      this.accessToken,
      [this.refreshToken,
      this.tokenEndpoint,
      this.scopes,
      this.expiration]);

/// Serializes a set of credentials to JSON. Nothing is guaranteed about the
  /// output except that it's valid JSON and compatible with
  /// [Credentials.toJson].
  String toJson() => JSON.stringify({
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenEndpoint': tokenEndpoint == null ? null : tokenEndpoint.toString(),
    'scopes': scopes,
    'expiration': expiration == null ? null : expiration.millisecondsSinceEpoch
  });

  /// Creates a new set of credentials using the supplied parameters
  static final dynamic using = (
      String accessToken,
      [String refreshToken,
       Uri tokenEndpoint,
       List<String> scopes,
       DateTime expiration]) {
    return new OAuthCredentials._(
        accessToken,
        refreshToken,
        tokenEndpoint,
        scopes,
        expiration);
  };

  static final dynamic fromJSON = (String json) {
    void validate(bool condition, String message) {
      if (condition) return;
      throw new FormatException(
          'Failed to load credentials: $message.\n\n$json');
    }

    var parsed;
    try {
      parsed = JSON.parse(json);
    } catch (e) {
      // Comment from oauth2 pub library
      // TODO(nweiz): narrow this catch clause once issue 6775 is fixed.
      validate(false, 'invalid JSON');
    }

    validate(parsed is Map, 'was not a JSON map');
    validate(parsed.containsKey('accessToken'),
        'did not contain required field "accessToken"');
    validate(parsed['accessToken'] is String,
        'required field "accessToken" was not a string, was '
        '${parsed['accessToken']}');

    var accessToken = parsed['accessToken'];

    for (var stringField in ['refreshToken', 'tokenEndpoint']) {
      var value = parsed[stringField];
      validate(value == null || value is String,
          'field "$stringField" was not a string, was "$value"');
    }

    var refreshToken = parsed['refreshToken'];

    var scopes = parsed['scopes'];
    validate(scopes == null || scopes is List,
        'field "scopes" was not a list, was "$scopes"');

    var tokenEndpoint = parsed['tokenEndpoint'];
    if (tokenEndpoint != null) {
      tokenEndpoint = Uri.parse(tokenEndpoint);
    }
    var expiration = parsed['expiration'];
    if (expiration != null) {
      validate(expiration is int,
          'field "expiration" was not an int, was "$expiration"');
      expiration = new DateTime.fromMillisecondsSinceEpoch(expiration);
    }

    return using(
        accessToken,
        refreshToken,
        tokenEndpoint,
        scopes,
        expiration);
  };
}