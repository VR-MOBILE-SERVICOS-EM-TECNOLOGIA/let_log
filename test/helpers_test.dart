import 'package:flutter_test/flutter_test.dart';
import 'package:let_log/let_log.dart';

void main() {
  group('debugBuildCurl', () {
    test('produces curl command with method, url, headers and data', () {
      final n = LoggerNet(
        api: 'https://h/u',
        type: 'POST',
        reqHeaders: '{"Authorization": "Bearer abc"}',
        req: '{"a":1}',
      );
      final result = debugBuildCurl(n);
      expect(result, startsWith("curl -X POST 'https://h/u'"));
      expect(result, contains("-H 'Authorization: Bearer abc'"));
      expect(result, contains("--data '{\"a\":1}'"));
    });
  });

  group('debugParseHeaders', () {
    test('parses JSON headers', () {
      final result = debugParseHeaders('{"a":"1","b":"2"}');
      expect(result, equals({'a': '1', 'b': '2'}));
    });

    test('parses Map.toString style headers', () {
      final result = debugParseHeaders('{a: 1, b: 2}');
      expect(result, equals({'a': '1', 'b': '2'}));
    });

    test('null returns empty map', () {
      expect(debugParseHeaders(null), isEmpty);
    });

    test('"null" string returns empty map', () {
      expect(debugParseHeaders('null'), isEmpty);
    });
  });

  group('debugPrettyJson', () {
    test('formats valid JSON with newlines', () {
      final result = debugPrettyJson('{"a":1,"b":[1,2]}');
      expect(result, contains('\n'));
    });

    test('returns non-JSON unchanged', () {
      expect(debugPrettyJson('not json'), equals('not json'));
    });
  });

  group('debugExportSession', () {
    test('contains export header and counts line', () {
      final net = LoggerNet(api: 'api/test', type: 'Http');
      final log = LoggerLog(message: 'test message');
      final result = debugExportSession(nets: [net], logs: [log]);
      expect(result, contains('=== LetLog session export ==='));
      expect(result, contains('Logs: 1 | Requests: 1'));
    });
  });
}
