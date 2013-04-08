library deny_test;

import 'package:unittest/unittest.dart';

// Unit tests
part 'src/oauth2_credentials_test.dart';
part 'src/oauth2_test.dart';
part 'src/query_string_test.dart';

void main() {
  query_string_tests();
  oauth2_tests();
  oauth2_credentials_tests();
}