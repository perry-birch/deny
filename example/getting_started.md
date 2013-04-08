
* Get an account and register an application
* http://instagram.com/developer/

	var auth = Instagram.authorizeUsing(
        '0993c79435a74c36b7cb6ba9e10a37a6', // CLIENT_ID
        '959e56f63e304faaa3179fe60f6c74ed', // CLIENT_SECRET
        new Uri('http://yourawesomesite.heroku.com/oauth2'),
        ['your', 'scopes']
        );
        
	redirectOAuth(HttpRequest request) {
	  var state = '2104';
	  var authUrl = auth.getAuthorizationUrl(state);
	  var response = request.response;
	  response
	    ..statusCode = HttpStatus.OK
	    ..headers.set(HttpHeaders.CONTENT_TYPE, 'text/html')
	    ..write(
	      '<!DOCTYPE html>'
	      '<meta http-equiv="Refresh" content="0; url=\'${authUrl}\'">'
	      'Redirecting to Instagram login...'
	    )
	    ..close();
	}
	
	oauth2(HttpRequest request) {
	  var client = new http.Client();
	  var handler = auth.handleTokenResponse(client, request.queryParameters);
	  handler.then((credentials) {
	    var response = request.response;
	    response
	    ..headers.set(HttpHeaders.CONTENT_TYPE, 'application/json')
	    ..write(credentials.toJson());
	    var instagram = Instagram.using(client, credentials);
	    var futures = [
	      instagram.getCurrentUser().then((userData) {
	        response
	        ..write('\r\n\r\n')
	        ..write(JSON.stringify(userData));
	      }),
	      instagram.getCurrentUserFeed(count: 3).then((userFeed) {
	        response
	        ..write('\r\n\r\n')
	        ..write(userFeed);
	      }),
	      instagram.getSearch('kavan').then((results) {
	        response
	        ..write('\r\n\r\n')
	        ..write(results);
	      }),
	    ];
	    Future.wait(futures).then((_) {
	      response
	      ..close();
	    });
	  });
	}