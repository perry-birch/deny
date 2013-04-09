# Deny: Instagram

----

> Gettings started with Instagram

Once you have an Instagram account you should visit the 
[Instagram Developer Site](http://instagram.com/developer/)
to read their extensive documentation and get set up.

*The rest of this guid will mostly focus on this implementation and not the API itself*

> Instagram breaks their API into 8 distinct areas:
- Users
- Relationships
- Media
- Comments
- Likes
- Tags
- Locations
- Geographies

*I'm listing the operations here to provide an overview*

> Users
- GET /users/{user-id}
- GET /users/self/feed
- GET /users/{user-id}/media/recent
- GET /users/self/media/liked
- GET /users/search

> Relationships
- GET /users/{user-id}/follows
- GET /users/{user-id}/followed-by
- GET /users/self/requested-by
- GET /users/{user-id}/relationship
- POST /users/{user-id}/relationship

> Media
- GET /media/{media-id}
- GET /media/search
- GET /media/popular

> Comments
- GET /media/{media-id}/comments
- POST /media/{media-id}/comments
- DEL /media/{media-id}/comments/{comment-id}

> Likes
- GET /media/{media-id}/likes
- POST /media/{media-id}/likes
- DEL /media/{media-id}/likes

> Tags
- GET /tags/{tag-name}
- GET /tags/{tag-name}/media/recent
- GET /tags/search

> Locations
- GET /locations/{location-id}
- GET /locations/{location-id}/media/recent
- GET /locations/search

> Geographies
- GET /geographies/{geo-id}/media/recent

> Until more features are rolled out with built in calls you can access any of these features using the low level OAuth2 to provide the authentication at least

> Structure of this API proxy:
> (See getting_started.md for an example. *should be duplicated here at some point*)

    InstagramApi
    - dynamic get(String path, [Map<String, String> parameters]);
    - dynamic search(String q, {int count});
    
    InstagramUser
    - dyamic getProfile();
    - dynamic getMediaRecent({int count, int minId, int maxId, int minTimestamp, int maxTimestamp});
    
    InstagramAuthenticatedUser
    - dynamic getFeed({int count, int minId, int maxId});
    - dynamic getMediaLiked({int count, int maxLikeId});