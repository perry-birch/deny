library deny_test;

import 'dart:uri';

import 'package:unittest/unittest.dart';
import 'package:deny/deny.dart';

// Unit tests
import 'src/oauth2_credentials_test.dart';
import 'src/oauth2_test.dart';
import 'src/query_string_test.dart';

void main() {
  query_string_tests();
  oauth2_tests();
  oauth2_credentials_tests();
}