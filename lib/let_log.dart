library let_log;

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:sqflite/sqlite_api.dart';
part 'log_widget.dart';
part 'net_widget.dart';
part 'db_widget.dart';

enum _Type { log, debug, warn, error }
List<String> _printNames = ["😄", "🐛", "❗", "❌", "⬆️", "⬇️"];
List<String> _tabNames = ["[Log]", "[Debug]", "[Warn]", "[Error]"];
List<int> _tabLevel = [500, 0, 1000, 1500];
final RegExp _tabReg = RegExp(r"\[|\]");

String _getTabName(int index) {
  return _tabNames[index].replaceAll(_tabReg, "");
}

class _Config {
  /// Whether to display the log in reverse order
  bool reverse = false;

  /// Whether or not to print logs in the ide
  bool printNet = true;

  /// Whether or not to print net logs in the ide
  bool printLog = true;

  /// Maximum number of logs, larger than this number, will be cleaned up, default value 500
  int maxLimit = 500;

  /// Set the names in ide print.
  void setPrintNames({
    String? log,
    String? debug,
    String? warn,
    String? error,
    String? request,
    String? response,
  }) {
    _printNames = [
      log ?? "[Log]",
      debug ?? "[Debug]",
      warn ?? "[Warn]",
      error ?? "[Error]",
      request ?? "[Req]",
      response ?? "[Res]",
    ];
  }

  /// Set the names in the app.
  void setTabNames({
    String? log,
    String? debug,
    String? warn,
    String? error,
    String? request,
    String? response,
  }) {
    _tabNames = [
      log ?? "[Log]",
      debug ?? "[Debug]",
      warn ?? "[Warn]",
      error ?? "[Error]",
    ];
  }
}

class Logger extends StatelessWidget {
  final Future<Database?>? dbFuture;

  const Logger({
    this.dbFuture,
  });

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabsList = [
      const Tab(child: Text("Log")),
      const Tab(child: Text("Net"))
    ];
    final List<Widget> tabsViewsList = [
      const LogWidget(),
      const NetWidget(),
    ];

    if (dbFuture != null) {
      tabsList.add(
        const Tab(child: Text("Banco de dados", textAlign: TextAlign.center))
      );

      tabsViewsList.add(
        DBWidget(dbFuture: dbFuture)
      );
    }

    return DefaultTabController(
      length: tabsList.length,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            tabs: tabsList,
          ),
          elevation: 0,
        ),
        body: TabBarView(
          children: tabsViewsList,
        ),
      ),
    );
  }

  static bool enabled = true;
  static _Config config = _Config();

  /// Logging
  static void log(Object time, Object message,
      {Object? detail,
      String timeColor = '\x1B[37m',
      String msgColor = '\x1B[34m'}) {
    if (enabled) {
      _Log.length.value++;
      _Log.add(_Type.log, time, message, detail, timeColor, msgColor);
    }
  }

  /// Record debug information
  static void debug(Object time, Object message,
      {Object? detail,
      String timeColor = '\x1B[37m',
      String msgColor = '\x1B[34m'}) {
    if (enabled) {
      _Log.length.value++;
      _Log.add(_Type.debug, time, message, detail, timeColor, msgColor);
    }
  }

  /// Record warnning information
  static void warn(Object time, Object message,
      {Object? detail,
      String timeColor = '\x1B[37m',
      String msgColor = '\x1B[34m'}) {
    if (enabled) {
      _Log.length.value++;
      _Log.add(_Type.warn, time, message, detail, timeColor, msgColor);
    }
  }

  /// Record error information
  static void error(Object time, Object message,
      {Object? detail,
      String timeColor = '\x1B[37m',
      String msgColor = '\x1B[34m'}) {
    if (enabled) {
      _Log.length.value++;
      _Log.add(_Type.error, time, message, detail, timeColor, msgColor);
    }
  }

  /// Start recording time
  static void time(Object key) {
    if (enabled) _Log.time(key);
  }

  /// End of record time
  static void endTime(Object key) {
    if (enabled) _Log.endTime(key);
  }

  /// Clearance log
  static void clear() {
    _Log.clear();
  }

  /// Recording network information
  static void net(String api,
      {String type = "Http", int status = 100, Object? data}) {
    if (enabled) _Net.request(api, type, status, data, '\x1B[32m');
  }

  /// End of record network information, with statistics on duration and size.
  static void endNet(String api,
      {int status = 200, Object? data, Object? headers, String? type}) {
    if (enabled) _Net.response(api, status, data, headers, type, '\x1B[32m');
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Future<Database?>>('dbFuture', dbFuture));
  }
}

class _Log {
  static final List<_Log> list = [];
  static final ValueNotifier<int> length = ValueNotifier(0);
  static final Map<Object, Object> _map = {};

  final _Type? type;
  final String? message;
  final String? detail;
  final DateTime? start;
  const _Log({this.type, this.message, this.detail, this.start});

  String get typeName {
    return _printNames[type!.index];
  }

  String get tabName {
    return _tabNames[type!.index];
  }

  int get tabLevel {
    return _tabLevel[type!.index];
  }

  bool contains(String keyword) {
    if (keyword.isEmpty) return true;
    return message != null && message!.contains(keyword) ||
        detail != null && detail!.contains(keyword);
  }

  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.writeln("Message: $message");
    sb.writeln("Time: $start");
    if (detail != null && detail!.length > 100) {
      sb.writeln("Detail: ");
      sb.writeln(detail);
    } else {
      sb.writeln("Detail: $detail");
    }

    return sb.toString();
  }

  static void add(_Type type, Object time, Object value, Object? detail,
      String timeColor, String msgColor) {
    final log = _Log(
      type: type,
      message: value.toString(),
      detail: detail.toString(),
      start: DateTime.now(),
    );
    list.add(log);
    _clearWhenTooMuch();
    if (Logger.config.printLog) {
      if (kIsWeb)
        debugPrint(
            '${log.typeName} $time${log.message}${log.detail == 'null' ? '' : ' ${log.detail}'}\n--------------------------------');
      else {
        dev.log(
            '${log.typeName} $timeColor$time$msgColor${log.message}\x1B[0m${log.detail == 'null' ? '' : ' ${log.detail}'}\n--------------------------------',
            level: log.tabLevel,
            time: DateTime.now());
      }
    }
  }

  static void _clearWhenTooMuch() {
    if (list.length > Logger.config.maxLimit) {
      list.removeRange(0, (Logger.config.maxLimit * 0.2).ceil());
    }
  }

  static void time(Object key) {
    _map[key] = DateTime.now();
  }

  static void endTime(Object key) {
    final data = _map[key];
    if (data != null) {
      _map.remove(key);
      final spend = DateTime.now().difference(data as DateTime).inMilliseconds;
      _Log.add(_Type.log, 'DateTime.now()', '$key: $spend ms', null, '\x1B[37m',
          '\x1B[34m');
    }
  }

  static void clear() {
    list.clear();
    _map.clear();
    length.value = 0;
  }
}

class _Net extends ChangeNotifier {
  static const all = "All";
  static final List<_Net> list = [];
  static final ValueNotifier<int> length = ValueNotifier(0);
  static final Map<String, _Net> _map = {};
  static final List<String> types = [all];
  static final ValueNotifier<int> typeLength = ValueNotifier(1);

  final String? api;
  final String? req;
  final DateTime? start;
  String? type;
  int status = 100;
  int spend = 0;
  String? res;
  String? headers;
  bool showDetail = false;
  int _reqSize = -1;
  int _resSize = -1;

  _Net({
    this.api,
    this.type,
    this.req,
    this.headers,
    this.start,
    this.res,
    this.spend = 0,
    this.status = 100,
  });

  int getReqSize() {
    if (_reqSize > -1) return _reqSize;
    if (req != null && req!.isNotEmpty) {
      try {
        return _reqSize = utf8.encode(req!).length;
      } catch (e) {
        // print(e);
      }
    }
    return 0;
  }

  int getResSize() {
    if (_resSize > -1) return _resSize;
    if (res != null && res!.isNotEmpty) {
      try {
        return _resSize = utf8.encode(res!).length;
      } catch (e) {
        // print(e);
      }
    }
    return 0;
  }

  bool contains(String keyword) {
    if (keyword.isEmpty) return true;
    return api!.contains(keyword) ||
        req != null && req!.contains(keyword) ||
        res != null && res!.contains(keyword);
  }

  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.writeln("[$status] $api");
    sb.writeln();
    sb.writeln("Start: $start");
    sb.writeln("Spend: $spend ms");
    sb.writeln("Headers: $headers");
    sb.writeln();
    sb.writeln("Request: $req");
    sb.writeln();
    sb.writeln("Response: $res");
    return sb.toString();
  }

  static void request(
      String api, String type, int status, Object? data, String msgColor) {
    final net = _Net(
      api: api,
      type: type,
      status: status,
      req: data?.toString(),
      start: DateTime.now(),
    );
    list.add(net);
    _map[api] = net;
    if (type != "" && !types.contains(type)) {
      types.add(type);
      typeLength.value++;
    }
    _clearWhenTooMuch();
    length.value++;

    if (Logger.config.printNet) {
      if (kIsWeb)
        debugPrint(
            '${_printNames[4]} ${DateTime.now()} ${'$type: '}${net.api}${net.req == null ? '' : ' Data: ${net.req}'}\n--------------------------------');
      else
        dev.log(
            '${_printNames[4]} (${DateTime.now()}) ${'$type: '}\x1B[103m\x1B[30m${net.api}\x1B[0m${net.req == null ? '' : ' Data: $msgColor${net.req}\x1B[0m'}\n--------------------------------',
            time: DateTime.now());
    }
  }

  static void _clearWhenTooMuch() {
    if (list.length > Logger.config.maxLimit) {
      list.removeRange(0, (Logger.config.maxLimit * 0.2).ceil());
    }
  }

  static void response(String api, int status, Object? data, Object? headers,
      String? type, String msgColor) {
    _Net? net = _map[api];
    if (net != null) {
      _map.remove(net);
      net.spend = DateTime.now().difference(net.start!).inMilliseconds;
      net.status = status;
      net.headers = headers?.toString();
      net.res = data?.toString();
      length.notifyListeners();
    } else {
      net = _Net(api: api, start: DateTime.now(), type: type);
      net.status = status;
      net.headers = headers?.toString();
      net.res = data?.toString();
      list.add(net);
      _clearWhenTooMuch();
      length.value++;
    }
    if (Logger.config.printNet) {
      if (kIsWeb)
        debugPrint(
            '${_printNames[5]} ${DateTime.now()} ${net.type == null ? '' : '${net.type}: '}{net.api}${net.res == null ? '' : ' Data: ${net.res}'}\nSpend: ${net.spend} ms\n--------------------------------');
      else
        dev.log(
            '${_printNames[5]} (${DateTime.now()}) ${net.type == null ? '' : '${net.type}: '}\x1B[106m\x1B[30m${net.api}\x1B[0m${net.res == null ? '' : ' Data: $msgColor${net.res}\x1B[0m'}\nSpend: ${net.spend} ms\n--------------------------------',
            time: DateTime.now());
    }
  }

  static void clear() {
    list.clear();
    _map.clear();
    length.value = 0;
  }
}
