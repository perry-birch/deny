library oauth2;

import 'dart:async';
import 'dart:collection';
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
  /// ndicates if your application needs to access a Google API when the
  /// user is not present at the browser. This parameter defaults to online.
  /// If your application needs to refresh access tokens when the user is not
  /// present at the browser, then use offline. This will result in your
  /// application obtaining a refresh token the first time your application
  /// exchanges an authorization code for a user.
  final String _accessType;// [ online | offline ]
  /// Indicates if the user should be re-prompted for consent. The default
  /// is auto, so a given user should only see the consent page for a given
  /// set of scopes the first time through the sequence. If the value is
  /// force, then the user sees a consent page even if they have previously
  /// given consent to your application for a given set of scopes.
  final String _approvalPrompt;// [ force | auto ]

  const OAuth2._(
      this._identifier,
      this._secret,
      this._authorizationEndpoint,
      this._tokenEndpoint,
      this._redirectEndpoint,
      this._scopes,
      this._accessType,
      this._approvalPrompt);

  static final dynamic from = (
    String identifier,
    String secret,
    Uri authorizationEndpoint,
    Uri tokenEndpoint,
    Uri redirectEndpoint,
    List<String> scopes,
    {
      String accessType: 'online',
      String approvalPrompt: 'force'
    }
    ) {
    if(accessType == null) { accessType = 'online'; }
    return new OAuth2._(
        identifier,
        secret,
        authorizationEndpoint,
        tokenEndpoint,
        redirectEndpoint,
        scopes,
        accessType,
        approvalPrompt);
  };

  static final dynamic attachCredentials = (http.BaseRequest request, OAuth2Credentials credentials) {
    request.headers['authorization'] = 'Bearer ${credentials.accessToken}';
  };

  static final dynamic validate = (http.BaseResponse response) {
    if(response.statusCode != 401 ||
        !response.headers.containsKey('www-authenticate')) {
      return response;
    }
    var authenticate;
    try {
      authenticate = new AuthenticateHeader.parse(
          response.headers['www-authenticate']);
    } on FormatException catch (e) {
      return response;
    }

    if (authenticate.scheme != 'bearer') return response;

    var params = authenticate.parameters;
    if (!params.containsKey('error')) return response;

    throw new AuthorizationException(
        params['error'], params['error_description'], params['error_uri']);
  };

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
      'access_type': this._accessType,
      'approval_prompt': this._approvalPrompt,
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

  Map<String, String> getTokenRefreshData(String refreshToken, [List<String> scopes = []]) {
    var data = {
      "grant_type": "authorization_code",
      "refresh_token": refreshToken,
      "redirect_uri": this._redirectEndpoint.toString(),
      // TODO(nweiz): the spec recommends that HTTP basic auth be used in
      // preference to form parameters, but Google doesn't support that. Should
      // it be configurable?
      "client_id": this._identifier,
      "client_secret": this._secret,
      "scope": scopes.join(' ')
    };
    return data;
  }

  Future<OAuth2Credentials> handleTokenResponse(http.Client client, Map<String, String> queryParameters) {
    var params = queryParameters;
    // Throws if an error is found
    _checkForResponseError(params);
    _checkForRequiredParams(params, ['code']);
    var code = params['code'];
    var data = getTokenRequestData(code);
    var state = params['state'];
    // Timestamp for the initial token request
    var requestTimeStamp = new DateTime.now();
    // Trigger post to auth server to get token
    return _postToTokenEndpoint(client, requestTimeStamp, data, state);
  }

  /// Explicitly refreshes this client's credentials. Returns this client.
  ///
  /// This will throw a [StateError] if the [Credentials] can't be refreshed, an
  /// [AuthorizationException] if refreshing the credentials fails, or a
  /// [FormatError] if the authorization server returns invalid responses.
  ///
  /// You may request different scopes than the default by passing in
  /// [newScopes]. These must be a subset of the scopes in the
  /// [Credentials.scopes] field of [Client.credentials].
  Future<OAuth2Credentials> refreshCredentials(
      http.Client client,
      OAuth2Credentials credentials,
      [List<String> newScopes]) {
    if(client == null) { throw new Exception('Invalid web client'); }
    return async.then((_) {
      // Make sure we're able to refresh
      if(!credentials.canRefresh) {
        var prefix = "OAuth credentials";
        if (credentials.isExpired) prefix = "$prefix have expired and";
        throw new StateError("$prefix can't be refreshed.");
      }
      var scopes = newScopes != null ? newScopes : this._scopes;
      var data = getTokenRefreshData(credentials.refreshToken, scopes);
      // Timestamp for the initial token request
      var requestTimeStamp = new DateTime.now();
      // Send refresh request
      return _postToTokenEndpoint(client, requestTimeStamp, data); // No state on refresh
    });
  }

  Future<OAuth2Credentials> _postToTokenEndpoint(http.Client client, DateTime requestTimeStamp, dynamic data, [dynamic state]) {
    return client.post(this._tokenEndpoint, fields: data)
        .then((response) {
          // Anything other than a 200 response is invalid and will throw
          _handlePostErrorResponse(
              response.statusCode,
              response.reasonPhrase,
              response.headers,
              response.body);
          // Extract the json data from the response
          var parameters = _parseJsonResponse(
              response.headers,
              response.body);

          return _extractCredentials(requestTimeStamp, parameters, state);
        });
  }


  OAuth2Credentials _extractCredentials(DateTime requestTimeStamp, LinkedHashMap<String, dynamic> parameters, String state) {
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
    if(!parameters.containsKey('token_type')) { parameters['token_type'] = 'bearer'; }
    if(!supportedTokenTypes.contains(parameters['token_type'])) {
      throw new FormatException('OAuth2 token type ${parameters['token_type']} is not supported');
    }
    var tokenType = parameters['token_type'];

    var refreshToken = null;
    if(parameters.containsKey('refresh_token')) {
      refreshToken = parameters['refresh_token'].toString();
    }
    var scopes = null;
    if(parameters.containsKey('scope')) {
      scopes = parameters['scope'].split(' ');
    }
    if(scopes == null) {
      scopes = this._scopes;
    }

    // Figure out the expiration time (if applicable)
    DateTime expiration = null;
    if(parameters.containsKey('expires_in')) {
      var expiresIn = parameters['expires_in'];
      if(expiresIn is int) {
        var duration = new Duration(seconds: expiresIn - _EXPIRATION_GRACE);
        expiration = requestTimeStamp.add(duration);
      }
    }

    return OAuth2Credentials.using(
        accessToken,
        refreshToken,
        this._tokenEndpoint,
        scopes,
        expiration,
        state,
        parameters);
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

  dynamic _parseJsonResponse(
    Map responseHeaders,
    String responseBody)
  {
    var contentType = responseHeaders['content-type'];
    if(contentType == null || contentType != 'application/json') {
      throw new FormatException('OAuth2 response must be in json');
    }

    var parameters;
    try {
      parameters = JSON.parse(responseBody);
    } catch (e) {
      // TODO(nweiz): narrow this catch clause once issue 6775 is fixed.
      throw new FormatException('OAuth2 response must be valid json');
    }
    return parameters;
  }

  /// Throws the appropriate exception for an error response from the
  /// authorization server.
  void _handlePostErrorResponse(
    int responseStatusCode,
    String responseReasonPhrase,
    Map responseHeaders,
    String responseBody)
  {
    if(responseStatusCode == 200) { return; }

    // OAuth2 mandates a 400 or 401 response code for access token error
    // responses. If it's not a 400 reponse, the server is either broken or
    // off-spec.
    if (responseStatusCode != 400 && responseStatusCode != 401) {
      var reason = '';
      if (responseReasonPhrase != null && !responseReasonPhrase.isEmpty) {
        ' ${responseReasonPhrase}';
      }
      throw new FormatException('OAuth request for "${this._tokenEndpoint}" failed '
          'with status ${responseStatusCode}${reason}.\n\n${responseBody}');
    }

    var parameters = _parseJsonResponse(
        responseHeaders,
        responseBody);

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