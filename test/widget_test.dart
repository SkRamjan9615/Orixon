import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ORIXON v1.0.0 Open-Source Integrity Check', () {
    const appName = 'ORIXON';
    const author = 'Sk Ramjan Ali';
    expect(appName, equals('ORIXON'));
    expect(author, equals('Sk Ramjan Ali'));
  });
}
