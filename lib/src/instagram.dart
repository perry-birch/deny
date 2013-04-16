library instagram;

import 'dart:json' as JSON;
import 'dart:uri';

import 'package:http/http.dart' as http;

import 'package:deny/deny.dart';

part 'instagram/instagram_user.dart';
part 'instagram/instagram_authenticated_user.dart';

//http://instagram.com/developer/endpoints/
class InstagramApi {
  static final Uri _AUTHORIZATION_ENDPOINT = new Uri('https://api.instagram.com/oauth/authorize/');
  static final Uri _TOKEN_ENDPOINT = new Uri('https://api.instagram.com/oauth/access_token');

  static const String _apiRootUrl = 'https://api.instagram.com/v1';

  final http.Client _client;
  final OAuth2Credentials _credentials;

  InstagramApi._(
      this._client,
      this._credentials);

  factory InstagramApi(
      http.Client client,
      OAuth2Credentials credentials) {
    return new InstagramApi._(client, credentials);
  }

  http.Client get client => _client;
  OAuth2Credentials get credentials => _credentials;

  InstagramAuthenticatedUser _currentUser;
  InstagramAuthenticatedUser get currentUser {
    if(_currentUser == null) {
      var userId = _credentials.parameterData['user']['id'];
      _currentUser = new InstagramUser(this, userId);
    }
    return _currentUser;
  }

  static final dynamic authorizeUsing = (
      String identifier,
      String secret,
      Uri redirectEndpoint,
      List<String> scopes, // [ basic, likes | relationships | comments ]
      {
        String accessType: 'online',
        String approvalPrompt: 'force'
      }) {
    return OAuth2.from(
      identifier,
      secret,
      _AUTHORIZATION_ENDPOINT,
      _TOKEN_ENDPOINT,
      redirectEndpoint,
      scopes,
      accessType: accessType,
      approvalPrompt: approvalPrompt
    );
  };

  dynamic get(String path, [Map<String, String> parameters]) {
    var queryString = '';
    if(parameters != null) {
      parameters.forEach((key, value) {
        queryString = '${queryString}&${key}=${value}';
      });
    }
    var url = '${_apiRootUrl}${path}?access_token=${_credentials.accessToken}';
    if(queryString.length > 0) {
      url = '${url}&${queryString}';
    }
    return _client.get(url).then((response) {
      OAuth2.validate(response);
      return response.body;
    });
  }

  dynamic search(String q, {int count}) {
    Map<String, String> params = new Map<String, String>();
    if(q != null) { params['q'] = q; }
    if(count != null) { params['count'] = count.toString(); }

    return get('/users/search', params);
  }


// var userId = _credentials.parameterData['user']['id'];
// Sample data structure returned from initial auth request
//{
//  "accessToken":"346114496.c023236.fa207142712a468e9ceb9e72a8a15087",
//  "refreshToken":null,
//  "tokenEndpoint":"https://api.instagram.com/oauth/access_token",
//  "scopes":["basic","comments"],
//  "expiration":null,
//  "state":"2104",
//  "parameterData":
//  {
//    "access_token":"346114496.c023236.fa207142712a468e9ceb9e72a8a15087",
//    "user":
//    {
//      "username":"super_mario",
//      "bio":"",
//      "website":"",
//      "profile_picture":"http://images.ak.instagram.com/profiles/profile_123456789_75sq_1365295815.jpg",
//      "full_name":"Super Thomas Mario",
//      "id":"123456789"
//    },
//    "token_type":"bearer"
//  }
//}
}