library instagram;

import 'dart:uri';

import 'oauth2.dart';

class Instagram {
  static final Uri _AUTHORIZATION_ENDPOINT = new Uri('https://api.instagram.com/oauth/authorize/');
  static final Uri _TOKEN_ENDPOINT = new Uri('https://api.instagram.com/oauth/access_token');

  Instagram._();

  static final dynamic using = (
      String identifier,
      String secret,
      Uri redirectEndpoint,
      List<String> scopes) {
    return OAuth2.from(
      identifier,
      secret,
      _AUTHORIZATION_ENDPOINT,
      _TOKEN_ENDPOINT,
      redirectEndpoint,
      scopes
    );
  };
}