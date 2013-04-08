library oauth2;

import 'dart:async';
import 'dart:io';
import 'dart:json' as JSON;
import 'dart:uri';

import 'package:http/http.dart' as http;

import 'authorization_exception.dart';
import 'oauth2_credentials.dart';
import 'query_string.dart';

class OAuth2 {
  /// The amount of time, in seconds, to add as a "grace period" for credential
  /// expiration. This allows credential expiration checks to remain valid for a
  /// reasonable amount of time.
  static const _EXPIRATION_GRACE = 10;

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

  Map<String, String> getTokenRequestData(String authorizationCode) {
    var data = {
      "grant_type": "authorization_code",
      "code": authorizationCode,
      "redirect_uri": this._redirectEndpoint.toString(),
      // TODO(nweiz): the spec recommends that HTTP basic auth be used in
      // preference to form parameters, but Google doesn't support that. Should
      // it be configurable?
      "client_id": this._identifier,
      "client_secret": this._secret
    };
    return data;
  }

  Future<OAuth2Credentials> handleResponse(http.Client client, HttpRequest request) {
    var params = request.queryParameters;
    // Throws if an error is found
    _checkForResponseError(params);
    _checkForRequiredParams(params, ['code']);
    var code = params['code'];
    var data = getTokenRequestData(code);
    // Timestamp for the initial token request
    var startTime = new DateTime.now();
    client.post(this._tokenEndpoint, fields: data)
    .then((response) {
      // Anything other than a 200 response is invalid and will throw
      _handlePostErrorResponse(response);
      // Extract the json data from the response
      var parameters = _parseJsonResponse(response);

      // token_type parameter isn't implemented in some major auth providers
      // (instagram for one)
      //var requiredParams = ['access_token', 'token_type'];
      var requiredParams = ['access_token'];
      for(var param in requiredParams) {
        if(!parameters.containsKey(param) || !(parameters[param] is String)) {
          throw new FormatException('OAuth2 token response [${param}] is missing or invalid');
        }
      }
      var accessToken = parameters['access_token'];

      // TODO(nweiz): support the "mac" token type
      // (http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-01)
      var supportedTokenTypes = ['bearer'];
      if(!parameters.contains('token_type')) { parameters['token_type'] = 'bearer'; }
      if(!supportedTokenTypes.contains(parameters['token_type'])) {
        throw new FormatException('OAuth2 token type ${parameters['token_type']} is not supported');
      }
      var tokenType = parameters['token_type'];

      var refreshToken = null;
      if(parameters.contains('refresh_token')) {
        refreshToken = parameters['refresh_token'].toString();
      }
      var scopes = null;
      if(parameters.contains('scope')) {
        scopes = parameters['scope'].split(' ');
      }

      // Figure out the expiration time (if applicable)
      DateTime expiration = null;
      if(parameters.contains('expires_in')) {
        var expiresIn = parameters['expires_in'];
        if(expiresIn is int) {
          var duration = new Duration(seconds: expiresIn - _EXPIRATION_GRACE);
          expiration = startTime.add(duration);
        }
      }

      return OAuth2Credentials.using(
          accessToken,
          refreshToken,
          this._tokenEndpoint,
          scopes,
          expiration);
    });
  }

  dynamic _parseJsonResponse(http.Response response) {
    var contentType = response.headers['content-type'];
    if(contentType == null || contentType != 'application/json') {
      throw new FormatException('OAuth2 response must be in json');
    }

    var parameters;
    try {
      parameters = JSON.parse(response.body);
    } catch (e) {
      // TODO(nweiz): narrow this catch clause once issue 6775 is fixed.
      throw new FormatException('OAuth2 response must be valid json');
    }
    return parameters;
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
    var missing = exclude(required, params.keys);
    if(missing.length == 0) { return; }

    throw new FormatException('Invalid OAuth response for '
        '"${this._authorizationEndpoint}": did not contain required parameter(s) '
    '[${missing.join(' - ')}');
  }

  /// Throws the appropriate exception for an error response from the
  /// authorization server.
  void _handlePostErrorResponse(http.Response response) {
    if(response.statusCode == 200) { return; }

    // OAuth2 mandates a 400 or 401 response code for access token error
    // responses. If it's not a 400 reponse, the server is either broken or
    // off-spec.
    if (response.statusCode != 400 && response.statusCode != 401) {
      var reason = '';
      if (response.reasonPhrase != null && !response.reasonPhrase.isEmpty) {
        ' ${response.reasonPhrase}';
      }
      throw new FormatException('OAuth request for "${this._tokenEndpoint}" failed '
          'with status ${response.statusCode}${reason}.\n\n${response.body}');
    }

    var parameters = _parseJsonResponse(response);

    var requiredParams = ['error', 'error_description', 'error_uri'];
    for(var param in requiredParams) {
      if(!parameters.containsKey(param) || !(parameters[param] is String)) {
        throw new FormatException('OAuth2 error response [${param}] is missing or invalid');
      }
    }

    var error = parameters['error'];
    var error_description = parameters['error_description'];
    var error_uri = parameters['error_uri'];
    var uri = error_uri == null ? null : Uri.parse(error_uri);

    throw new AuthorizationException(error, error_description, uri);
  }

  Iterable exclude(Iterable target, Iterable other) {
    return target.where((t) => !other.contains(t));
  }

  Iterable intersection(Iterable left, Iterable right) {
    return left.map((l) => right.contains(l));

  }
}