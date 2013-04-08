part of deny_test;

oauth2_credentials_tests() {
  group('-oauth2_credentials- should', () {
    test('capture correct field data', () {
      // Arrange
      var accessToken = 'accessToken';
      var refreshToken = 'refreshToken';
      var tokenEndpoint = new Uri.fromString('http://tokenEndpoint.com');
      var scopes = ['scope1', 'scope2'];
      var expiration = new DateTime.now().add(new Duration(minutes: 5));

      // Act
      var credentials = OAuth2Credentials.using(
          accessToken,
          refreshToken,
          tokenEndpoint,
          scopes,
          expiration);

      // Assert
      expect(credentials.accessToken, accessToken);
      expect(credentials.refreshToken, refreshToken);
      expect(credentials.tokenEndpoint, tokenEndpoint);
      expect(credentials.scopes, scopes);
      expect(credentials.expiration, expiration);
    });

    test('not be expired if expiration is future', () {
      // Arrange
      var accessToken = 'accessToken';
      var refreshToken = 'refreshToken';
      var tokenEndpoint = new Uri.fromString('http://tokenEndpoint.com');
      var scopes = ['scope1', 'scope2'];
      var expiration = new DateTime.now().add(new Duration(minutes: 5));

      // Act
      var credentials = OAuth2Credentials.using(
          accessToken,
          refreshToken,
          tokenEndpoint,
          scopes,
          expiration);

      // Assert
      expect(credentials.isExpired, false);
    });

    test('be expired if expiration is past', () {
      // Arrange
      var accessToken = 'accessToken';
      var refreshToken = 'refreshToken';
      var tokenEndpoint = new Uri.fromString('http://tokenEndpoint.com');
      var scopes = ['scope1', 'scope2'];
      var expiration = new DateTime.now().add(new Duration(minutes: -5));

      // Act
      var credentials = OAuth2Credentials.using(
          accessToken,
          refreshToken,
          tokenEndpoint,
          scopes,
          expiration);

      // Assert
      expect(credentials.isExpired, true);
    });
  });
}