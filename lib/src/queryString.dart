library queryString;

import 'dart:uri';

class QueryString {
  final List<String> _encodedList;

  const QueryString._(this._encodedList);

  QueryString append(Map<String, String> parameters) {
    return appendAndEncode(this, parameters);
  }

  String flatten() {
    return _encodedList.join('&');
  }

  static final dynamic appendAndResolve = (Uri uri, Map<String, String> parameters) {
    return uri.resolve('?${fromUri(uri).append(parameters).flatten()}');
  };

  /**
   *  Provides extended manipulation capabilities on the query portion
   *  of the provided [Uri]
   */
  static final dynamic fromUri = (Uri uri) {
    return fromString(uri.query);
  };

  static final dynamic fromString = ([String encodedString = '']) {
    return fromEncodedList(encodedString.split('&'));
  };

  static final dynamic fromEncodedList = (List<String> encodedList) {
    return new QueryString._(encodedList);
  };

  static final dynamic appendAndEncode = (QueryString target, Map<String, String> parameters) {
    var encodedList = target._encodedList;
    parameters.forEach((key, value) {
      if(key == null) { key = ''; }
      if(value == null) { value = ''; }
      encodedList.add('${encodeUriComponent(key)}=${encodeUriComponent(value)}');
    });
    return fromEncodedList(encodedList);
  };
}