# Deny: Getting Started Doc

----

> Denial is the first step on the road to recovery... at least when you're talking about security.

  - Gotta have [Dart]: http://dartlang.org
  - You'll need an OAuth2 playground - [Instagram]: http://instagram.com/developer/
  - And maybe a place to run stuff - [Drone.io]: http://drone.io
  - Then you'll want to host it somewhere - [Heroku]: http://heroku.com 

----

Getting started is really easy *(I sincerly hope!)*:

>Grab something to help you with the auth:

    var auth = Instagram.authorizeUsing(
      '0993c79435a74c36b7cb6ba9e10a37a6', // CLIENT_ID
      '959e56f63e304faaa3179fe60f6c74ed', // CLIENT_SECRET
      new Uri('http://yourawesomesite.heroku.com/oauth2'),
      ['your', 'scopes']
    );

>Got some state? Add that.  Then send the user to the getAuthorizationUrl somehow...

    redirectOAuth2(HttpRequest request) { 
      var state = '2104'; // <-- *any string you want!*
      var authUrl = auth.getAuthorizationUrl(state);
      var response = request.response;
      response
      ..statusCode = HttpStatus.OK
      ..headers.set(HttpHeaders.CONTENT_TYPE, 'text/html')
      ..write(
        '<!DOCTYPE html>'
        ''
        'Redirecting to Instagram login...'
      )
      ..close();
    }

>Make sure there is someone listening when the auth service calls back

    oauth2(HttpRequest request) {
      var client = new http.Client();
      var handler = auth.handleTokenResponse(client, request.queryParameters);
      handler.then((credentials) { 
        var response = request.response; 
        response
        ..headers.set(HttpHeaders.CONTENT_TYPE, 'application/json')
        ..write(credentials.toJson()); // <-- dump a buch of text to the user, just for fun!

>Grab an API proxy to make your life oh so much easier

        var instagramApi = InstagramApi(client, credentials);

>Then, start casting about for some intersting JSON!

        var futures = [ 
          instagramApi.currentUser.getProfile().then((userData) {
            response
            ..write('\r\n\r\n')
            ..write(JSON.stringify(userData));
          }),
          instagramApi.currentUser.getFeed(count: 3).then((userFeed) {
            response
            ..write('\r\n\r\n')
            ..write(userFeed);
          }),
          instagramApi.search('luigi').then((results) {
            response
            ..write('\r\n\r\n')
            ..write(results);
          }),
        ];
        Future.wait(futures).then((_) {
          response ..close();
        });
      });
    }

----

Version
----

0.0.8 ish

Tech
----

* [Dart] - Dartlang.org: get the JS out!
* [Deny] - OAuth2 Library for Dart

Installation
----

[Deny]: http://pub.dartlang.org/packages/deny

License
----

https://github.com/Vizidrix/deny/blob/master/LICENSE

----
## Edited
* 08-April-2013 initial release
* 09-April-2013 added credits for the OAuth2 guys

----
## Credits
* Vizidrix <https://github.com/organizations/Vizidrix>
* Perry Birch <https://github.com/PerryBirch>
* Nathan Weizenbaum <nex342@gmail.com>
* Dan Grove <dgrove@google.com>
* John Messerly <jmesserly@google.com>
* Sigmund Cherem <sigmund@google.com>
