part of deny_test;

// These properties can/should be stored in a config for real apps
var identifier = '0993c79437a74c36b7cb6ba9e10a37a6';
var secret = '959e56f69e304faaa3179fe60f6c74ed';
var redirectPath = 'http://localhost:8080/oauth2';
var redirectUrl = new Uri(redirectPath);
var defaultScopes = ['basic', 'comments'];

dynamic getAuth() {
  var deny_localhost8080 = Instagram.using(
      identifier,
      secret,
      redirectUrl,
      defaultScopes
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
          '&access_type=online&'
          'approval_prompt=auto&'
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
          '&access_type=online&'
          'approval_prompt=auto&'
          'response_type=code&'
          'client_id=${identifier}&'
          'redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2&'
          'scope=${defaultScopes.join('+')}&'
          'state=${state}');
    });
  });
}