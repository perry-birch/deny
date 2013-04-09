part of instagram;

class InstagramUser {
  final InstagramApi _api;
  final String _userId;

  InstagramUser._(this._api, this._userId);

  factory InstagramUser(
      InstagramApi api,
      String userId) {
    return new InstagramUser._(api, userId);
  }

  InstagramApi get api => _api;

  /*
   *  Get basic information about a user.
   */
  dynamic getProfile() {
    return api.get('/users/${_userId}');
  }

  /*
   * Get the most recent media published by a user.
   *
   * count: Count of media to return.
   * minId: Return media later than this min_id.
   * maxId: Return media earlier than this max_id.
   * minTimestamp: Return media after the UNIX timestamp.
   * maxTimestamp: Return media before this UNIT timestamp.
   *
   */
  dynamic getMediaRecent({int count, int minId, int maxId, int minTimestamp, int maxTimestamp}) {
    Map<String, String> params = new Map<String, String>();
    if(count != null) { params['count'] = count.toString(); }
    if(minId != null) { params['min_id'] = minId.toString(); }
    if(maxId != null) { params['max_id'] = maxId.toString(); }
    if(minTimestamp != null) { params['min_timestamp'] = maxId.toString(); }
    if(maxTimestamp != null) { params['max_timestamp'] = minId.toString(); }

    return api.get('/users/${_userId}/media/recent', params);
  }
}