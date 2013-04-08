library oauth2;

import 'dart:async';
import 'dart:io';
import 'dart:uri';

import 'authorization_exception.dart';
import 'oauth2_credentials.dart';
import 'query_string.dart';

class OAuth2 {
  /// The client identifier for this client. The authorization server will issue
  /// each client a separate client identifier and secret, which allows the
  /// server to tell which client is accessing it. Some servers may also have an
  /// anonymous identifier/secret pair that any client may use.
  ///
  /// This is usually global to the program using this library.
  final String _identifier;
  /// The client secret for this client. The authorization server will issue
  /// each client a separate client identifier and secret, which allows the
  /// server to tell which client is accessing it. Some servers may also have an
  /// anonymous identifier/secret pair that any client may use.
  ///
  /// This is usually global to the program using this library.
  ///
  /// Note that clients whose source code or binary executable is readily
  /// available may not be able to make sure the client secret is kept a secret.
  /// This is fine; OAuth2 servers generally won't rely on knowing with
  /// certainty that a client is who it claims to be.
  final String _secret;
  /// A URL provided by the authorization server that serves as the base for the
  /// URL that the resource owner will be redirected to to authorize this
  /// client. This will usually be listed in the authorization server's
  /// OAuth2 API documentation.
  final Uri _authorizationEndpoint;
  /// A URL provided by the authorization server that this library uses to
  /// obtain long-lasting credentials. This will usually be listed in the
  /// authorization server's OAuth2 API documentation.
  final Uri _tokenEndpoint;
  /// The URL to which the resource owner will be redirected after they
  /// authorize this client with the authorization server.
  final Uri _redirectEndpoint;
  /// The scopes that the client is requesting access to.
  final List<String> _scopes;

  const OAuth2._(
      this._identifier,
      this._secret,
      this._authorizationEndpoint,
      this._tokenEndpoint,
      this._redirectEndpoint,
      this._scopes);

  static final dynamic from = (
    String identifier,
    String secret,
    Uri authorizationEndpoint,
    Uri tokenEndpoint,
    Uri redirectEndpoint,
    List<String> scopes
    ) {
    return new OAuth2._(
        identifier,
        secret,
        authorizationEndpoint,
        tokenEndpoint,
        redirectEndpoint,
        scopes);
  };

  // try to lookup existing credentials
  // if found then return new OAuth.Client(identifier, secret, credentials)
  // otherwise get the grant

  /// Returns the URL to which the resource owner should be redirected to
  /// authorize this client. The resource owner will then be redirected to
  /// [redirect], which should point to a server controlled by the client. This
  /// redirect will have additional query parameters that should be passed to
  /// [handleAuthorizationResponse].
  ///
  /// The specific permissions being requested from the authorization server may
  /// be specified via [scopes]. The scope strings are specific to the
  /// authorization server and may be found in its documentation. Note that you
  /// may not be granted access to every scope you request; you may check the
  /// [Credentials.scopes] field of [Client.credentials] to see which scopes you
  /// were granted.
  ///
  /// An opaque [state] string may also be passed that will be present in the
  /// query parameters provided to the redirect URL.
  ///
  /// https://developers.google.com/accounts/docs/OAuth2WebServer
  ///
  Uri getAuthorizationUrl([String state = '']) {
    if(state == null) { state = ''; } // Make sure null wasn't passed
    // Add the following parameters to the auth endpoint uri
    return QueryString.appendAndResolve(this._authorizationEndpoint, {
      'access_type': 'online', // [ online | offline ]
      'approval_prompt': 'auto', // [ force | auto ]
      'response_type': 'code',
      'client_id': this._identifier,
      'redirect_uri': this._redirectEndpoint.toString(),
      'scope': this._scopes.join(' '),
      'state': state
    });
  }

  Future<OAuthCredentials> handleResponse(HttpRequest request) {
    var params = request.queryParameters;
    // Throws if an error is found
    _checkForResponseError(params);
    if(!params.containsKey('code')) {
      throw new FormatException('Invalid OAuth response for '
          '"${this._authorizationEndpoint}": did not contain required parameter '
      '"code".');
    }
    //_authCodeGrant.getAuthorizationUrl(_redirectEndpoint, scopes: _scopes);
    /*_authCodeGrant.handleAuthorizationResponse(request.queryParameters)
      .then((client) {
          return client.credentials;
          //return client;
        });*/
    /*var credentials = OAuth.handleAccessTokenResponse(
        response,
        _tokenEndpoint,
        new DateTime.now(),
        _scopes);

    return credentials;*/
  }

  void _checkForResponseError(Map<String, String> params) {
    if(!params.containsKey('error')) { return; }
    // Error in query params indicates an error from the OAuth source
    var error = params['error'];
    var description = params['error_description'];
    var uriString = params['error_uri'];
    var uri = uriString == null ? null : Uri.parse(uriString);
    throw new AuthorizationException(error, description, uri);
  }

  void _checkForRequiredParams(Map<String, String> params, List<String> required) {
    if(union(required, params.keys).length != required.length) {
      throw new FormatException('Invalid OAuth response for '
          '"${this._authorizationEndpoint}": did not contain required parameter '
      '"code".');
    }
  }

  Iterable union(Iterable left, Iterable right) {
    return left.map((l) => right.contains(l));
  }
}