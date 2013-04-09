part of instagram;

class InstagramAuthenticatedUser extends InstagramUser {
  //final InstagramApi _api;
  //final String _userId;

  InstagramAuthenticatedUser(
      InstagramApi api,
      String userId)
      : super._(api, userId);

  /*
   * Get basic information about the authenticated user.
   */
  //dynamic getProfile() {
  //  return _api.get('/users/self');
  //}

  /*
   * See the authenticated user's feed.
   *
   * count: Count of media to return.
   * minId: Return media later than this min_id
   * maxId: Return media earlier than this max_id.
   */
  dynamic getFeed({int count, int minId, int maxId}) {
    Map<String, String> params = new Map<String, String>();
    if(count != null) { params['count'] = count.toString(); }
    if(minId != null) { params['min_id'] = minId.toString(); }
    if(maxId != null) { params['max_id'] = maxId.toString(); }

    return api.get('/users/self/feed', params);
  }

  /*
   * See the authenticated user's list of media they've liked.
   * Note that this list is ordered by the order in which the
   * user liked the media. Private media is returned as long
   * as the authenticated user has permission to view that
   * media.
   *
   * Liked media lists are only available for the currently
   * authenticated user.
   *
   * count: Count of media to return.
   * maxLikeId: Return media liked before this id.
   *
   */
  dynamic getMediaLiked({int count, int maxLikeId}) {
    Map<String, String> params = new Map<String, String>();
    if(count != null) { params['count'] = count.toString(); }
    if(maxLikeId != null) { params['max_like_id'] = maxLikeId.toString(); }

    return api.get('/users/self/media/liked');
  }
}