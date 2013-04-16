import 'package:unittest/unittest.dart';
import 'package:deny/deny.dart';
import 'dart:uri';

// These properties can/should be stored in a config for real apps
var identifier = '0993c79437a74c36b7cb6ba9e10a37a6';
var secret = '959e56f69e304faaa3179fe60f6c74ed';
var redirectPath = 'http://localhost:8080/oauth2';
var redirectUrl = new Uri.fromString(redirectPath);
var defaultScopes = ['basic', 'comments'];
var accessType = 'online';
var approvalPrompt = 'force';

dynamic getAuth() {
  var deny_localhost8080 = InstagramApi.authorizeUsing(
      identifier,
      secret,
      redirectUrl,
      defaultScopes,
      accessType: accessType,
      approvalPrompt: approvalPrompt
    );
  return deny_localhost8080;
}

oauth2_tests() {
  group('-oauth2- should', () {

    test('return correct authorization url', () {
      // Arrange
      var auth = getAuth();

      // Act
      var authUrl = auth.getAuthorizationUrl();

      // Assert
      expect(authUrl.toString(),
          'https://api.instagram.com/oauth/authorize/?'
          '&access_type=${accessType}&'
          'approval_prompt=${approvalPrompt}&'
          'response_type=code&'
          'client_id=${identifier}&'
          'redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2&'
          'scope=${defaultScopes.join('+')}&'
          'state=');
    });

    test('return include state authorization url if provided', () {
      // Arrange
      var auth = getAuth();
      var state = 'statedata';

      // Act
      var authUrl = auth.getAuthorizationUrl(state);

      // Assert
      expect(authUrl.toString(),
          'https://api.instagram.com/oauth/authorize/?'
          '&access_type=${accessType}&'
          'approval_prompt=${approvalPrompt}&'
          'response_type=code&'
          'client_id=${identifier}&'
          'redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2&'
          'scope=${defaultScopes.join('+')}&'
          'state=${state}');
    });

    //http://localhost:8080/oauth2?code=125535f857634bfb8cb6e17a12edbfa9&state=2103
  });
}