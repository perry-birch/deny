library instagram;

import 'dart:json' as JSON;
import 'dart:uri';

import 'package:http/http.dart' as http;

import 'package:deny/deny.dart';

//http://instagram.com/developer/endpoints/relationships/
class Instagram {
  static final Uri _AUTHORIZATION_ENDPOINT = new Uri('https://api.instagram.com/oauth/authorize/');
  static final Uri _TOKEN_ENDPOINT = new Uri('https://api.instagram.com/oauth/access_token');

  static const String _apiRootUrl = 'https://api.instagram.com/v1';

  final http.Client _client;
  final OAuth2Credentials _credentials;

  Instagram._(
      this._client,
      this._credentials);

  static final dynamic using = (
      http.Client client,
      OAuth2Credentials credentials) {
    return new Instagram._(client, credentials);
  };

  static final dynamic authorizeUsing = (
      String identifier,
      String secret,
      Uri redirectEndpoint,
      List<String> scopes,
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

  dynamic _callApi(String path, [Map<String, String> parameters]) {
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

  dynamic getCurrentUser() {
    var userId = _credentials.parameterData['user']['id'];
    return getUser(userId);
  }

  dynamic getCurrentUserFeed({int count, int minId, int maxId}) {
    Map<String, String> params = new Map<String, String>();
    if(count != null) { params['count'] = count.toString(); }
    if(minId != null) { params['min_id'] = minId.toString(); }
    if(maxId != null) { params['max_id'] = maxId.toString(); }

    return _callApi('/users/self/feed', params);
  }

  dynamic getCurrentUserMediaLiked({int count, int maxLikeId}) {
    Map<String, String> params = new Map<String, String>();
    if(count != null) { params['count'] = count.toString(); }
    if(maxLikeId != null) { params['max_like_id'] = maxLikeId.toString(); }

    return _callApi('/users/self/media/liked');
  }

  dynamic getUser(String userId) {
    return _callApi('/users/${userId}');
  }

  dynamic getMediaRecent(String userId, {int count, int minId, int maxId, int minTimestamp, int maxTimestamp}) {
    Map<String, String> params = new Map<String, String>();
    if(count != null) { params['count'] = count.toString(); }
    if(minId != null) { params['min_id'] = minId.toString(); }
    if(maxId != null) { params['max_id'] = maxId.toString(); }
    if(minTimestamp != null) { params['min_timestamp'] = maxId.toString(); }
    if(maxTimestamp != null) { params['max_timestamp'] = minId.toString(); }

    return _callApi('/users/${userId}/media/recent', params);
  }

  dynamic getSearch(String q, {int count}) {
    Map<String, String> params = new Map<String, String>();
    if(q != null) { params['q'] = q; }
    if(count != null) { params['count'] = count.toString(); }

    return _callApi('/users/search', params);
  }

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