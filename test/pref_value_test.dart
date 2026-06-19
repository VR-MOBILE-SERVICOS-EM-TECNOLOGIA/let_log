import 'package:flutter_test/flutter_test.dart';
import 'package:let_log/let_log.dart';

void main() {
  group('debugParsePrefValue', () {
    test('bool returns the toggled switch value, ignoring text', () {
      expect(debugParsePrefValue(false, true, ''), isTrue);
      expect(debugParsePrefValue(true, false, 'whatever'), isFalse);
    });

    test('valid int text parses to int', () {
      expect(debugParsePrefValue(0, false, ' 42 '), equals(42));
    });

    test('invalid int text returns null', () {
      expect(debugParsePrefValue(0, false, 'abc'), isNull);
    });

    test('valid double text parses to double', () {
      expect(debugParsePrefValue(0.0, false, '3.5'), equals(3.5));
    });

    test('invalid double text returns null', () {
      expect(debugParsePrefValue(0.0, false, 'x'), isNull);
    });

    test('String returns the raw text unchanged', () {
      expect(
        debugParsePrefValue('old', false, 'new value'),
        equals('new value'),
      );
    });

    test('List splits by line, trims, and drops empties', () {
      final result = debugParsePrefValue(<String>[], false, 'a\n  b  \n\nc\n');
      expect(result, equals(['a', 'b', 'c']));
    });
  });
}
