import 'package:flutter_test/flutter_test.dart';
import 'package:let_log/let_log.dart';

void main() {
  setUp(Logger.clear);

  group('LoggerLog basic', () {
    test('Logger.log adds one entry with correct label and message', () {
      Logger.log('t', 'hello world');
      expect(LoggerLog.list.length, 1);
      expect(LoggerLog.list.last.message, contains('hello world'));
      expect(LoggerLog.list.last.label, equals('LOG'));
      expect(LoggerLog.length.value, equals(1));
    });

    test('Logger.error stores detail and label ERROR', () {
      Logger.error('t', 'boom', detail: 'stacktrace');
      expect(LoggerLog.list.last.label, equals('ERROR'));
      expect(LoggerLog.list.last.detail, equals('stacktrace'));
    });

    test('origin and displayMessage parsed from bracketed prefix', () {
      Logger.log('t', '[Auth] token refreshed');
      final entry = LoggerLog.list.last;
      expect(entry.origin, equals('Auth'));
      expect(entry.displayMessage, equals('token refreshed'));
    });

    test('contains is case-insensitive', () {
      Logger.log('t', 'UserService ok');
      final entry = LoggerLog.list.last;
      expect(entry.contains('user'), isTrue);
      expect(entry.contains('zzz'), isFalse);
    });
  });

  group('Logger.clear', () {
    test('clears lists and resets lengths', () {
      Logger.log('t', 'something');
      Logger.net('api/clear-test');
      Logger.clear();
      expect(LoggerLog.list, isEmpty);
      expect(LoggerNet.list, isEmpty);
      expect(LoggerLog.length.value, equals(0));
      expect(LoggerNet.length.value, equals(0));
    });
  });

  group('maxLimit trim', () {
    late int savedLimit;

    setUp(() {
      savedLimit = Logger.config.maxLimit;
      Logger.config.maxLimit = 10;
    });

    tearDown(() {
      Logger.config.maxLimit = savedLimit;
      Logger.clear();
    });

    test('trims list when over maxLimit', () {
      for (var i = 0; i < 14; i++) {
        Logger.log('t', 'msg $i');
      }
      expect(LoggerLog.list.length, lessThanOrEqualTo(10));
    });
  });

  group('LoggerNet', () {
    test('net happy path: status, isError, isPending, resSize', () {
      Logger.net('api/x', data: {'a': 1});
      Logger.endNet('api/x', data: {'ok': true});
      expect(LoggerNet.list.length, equals(1));
      final n = LoggerNet.list.last;
      expect(n.status, equals(200));
      expect(n.isError, isFalse);
      expect(n.isPending, isFalse);
      expect(n.getResSize(), greaterThan(0));
    });

    test('net error: status 404 -> isError true', () {
      Logger.net('api/err');
      Logger.endNet('api/err', status: 404);
      final n = LoggerNet.list.last;
      expect(n.isError, isTrue);
    });

    test('net pending: no endNet -> isPending true', () {
      Logger.net('api/p');
      final n = LoggerNet.list.last;
      expect(n.isPending, isTrue);
    });

    test('types registry updated', () {
      Logger.net('ws/y', type: 'Socket');
      expect(LoggerNet.types, contains('Socket'));
    });
  });
}
