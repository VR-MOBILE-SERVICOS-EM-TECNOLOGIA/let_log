library let_log;

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqlite_api.dart';
part 'log_widget.dart';
part 'net_widget.dart';
part 'db_widget.dart';
part 'shared_prefs_widget.dart';
part 'theme.dart';
part 'live_list.dart';
part 'widgets.dart';
part 'net_export.dart';
part 'testing.dart';

enum _Type { log, debug, warn, error }

List<String> _printNames = ["😄", "🐛", "❗", "❌", "⬆️", "⬇️"];
List<String> _tabNames = ["[Log]", "[Debug]", "[Warn]", "[Error]"];
List<int> _tabLevel = [500, 0, 1000, 1500];
final RegExp _tabReg = RegExp(r"\[|\]");
final RegExp _originReg = RegExp(r"^\[([^\]]+)\]\s*(.*)$", dotAll: true);

const double _liveScrollTolerance = 48;

String _formatTimestamp(DateTime? value) {
  if (value == null) return "--:--:--.---";

  String two(int number) => number.toString().padLeft(2, "0");
  String three(int number) => number.toString().padLeft(3, "0");

  return "${two(value.hour)}:${two(value.minute)}:${two(value.second)}.${three(value.millisecond)}";
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return "${bytes}B";
  return "${(bytes / 1024).toStringAsFixed(1)}KB";
}

String _safePreview(String? value, {int maxLength = 220}) {
  if (value == null || value.trim().isEmpty || value == "null") return "";

  final normalized = value.trim().replaceAll(RegExp(r"\s+"), " ");
  if (normalized.length <= maxLength) return normalized;
  return "${normalized.substring(0, maxLength)}...";
}

String _extractResponseMessage(String? response) {
  if (response == null || response.trim().isEmpty || response == "null")
    return "";

  final cleaned = response
      .replaceFirst(RegExp(r"^Error:\s*", caseSensitive: false), "")
      .trim();
  try {
    final decoded = json.decode(cleaned);
    if (decoded is Map<String, dynamic>) {
      for (final key in const ["msg", "message", "error", "return"]) {
        final value = decoded[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
  } catch (_) {
    // Not JSON; use the raw response preview below.
  }

  return cleaned;
}

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

class Logger extends StatefulWidget {
  final Future<Database?>? dbFuture;
  final SharedPreferences? sheredPrefs;
  final Function()? onSelectFirstTab;
  final Function()? onSelectSecondTab;
  final Function()? onSelectThirdTab;
  final Function()? onSelectFourthTab;

  const Logger({
    this.dbFuture,
    this.sheredPrefs,
    this.onSelectFirstTab,
    this.onSelectSecondTab,
    this.onSelectThirdTab,
    this.onSelectFourthTab,
  });

  static bool enabled = true;
  static _Config config = _Config();

  /// Logging
  static void log(
    Object time,
    Object message, {
    Object? detail,
    String timeColor = '\x1B[37m',
    String msgColor = '\x1B[34m',
  }) {
    if (enabled) {
      LoggerLog.add(_Type.log, time, message, detail, timeColor, msgColor);
    }
  }

  /// Record debug information
  static void debug(
    Object time,
    Object message, {
    Object? detail,
    String timeColor = '\x1B[37m',
    String msgColor = '\x1B[34m',
  }) {
    if (enabled) {
      LoggerLog.add(_Type.debug, time, message, detail, timeColor, msgColor);
    }
  }

  /// Record warnning information
  static void warn(
    Object time,
    Object message, {
    Object? detail,
    String timeColor = '\x1B[37m',
    String msgColor = '\x1B[34m',
  }) {
    if (enabled) {
      LoggerLog.add(_Type.warn, time, message, detail, timeColor, msgColor);
    }
  }

  /// Record error information
  static void error(
    Object time,
    Object message, {
    Object? detail,
    String timeColor = '\x1B[37m',
    String msgColor = '\x1B[34m',
  }) {
    if (enabled) {
      LoggerLog.add(_Type.error, time, message, detail, timeColor, msgColor);
    }
  }

  /// Start recording time
  static void time(Object key) {
    if (enabled) LoggerLog.time(key);
  }

  /// End of record time
  static void endTime(Object key) {
    if (enabled) LoggerLog.endTime(key);
  }

  /// Recording network information
  static void net(
    String api, {
    String type = "Http",
    int status = 100,
    Object? data,
    Object? headers,
  }) {
    if (enabled)
      LoggerNet.request(api, type, status, data, headers, '\x1B[32m');
  }

  /// End of record network information, with statistics on duration and size.
  static void endNet(
    String api, {
    int status = 200,
    Object? data,
    Object? headers,
    String? type,
  }) {
    if (enabled)
      LoggerNet.response(api, status, data, headers, type, '\x1B[32m');
  }

  /// Clearance log
  static void clear() {
    LoggerLog.clear();
    LoggerNet.clear();
  }

  @override
  LoggerState createState() => LoggerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Future<Database?>?>('dbFuture', dbFuture),
    );
    properties.add(
      ObjectFlagProperty<Function()?>.has('onSelectLogTabs', onSelectFirstTab),
    );
    properties.add(
      ObjectFlagProperty<Function()?>.has('onSelectNetTabs', onSelectSecondTab),
    );
    properties.add(
      ObjectFlagProperty<Function()?>.has('onSelectDBTabs', onSelectThirdTab),
    );
    properties.add(
      DiagnosticsProperty<SharedPreferences?>('sheredPrefs', sheredPrefs),
    );
    properties.add(
      ObjectFlagProperty<Function()?>.has(
        'onSelectFourthTab',
        onSelectFourthTab,
      ),
    );
  }
}

class LoggerState extends State<Logger> with TickerProviderStateMixin {
  late TabController tabsController;
  late final List<Tab> tabsList;
  final List<Widget> tabsViewsList = [const LogWidget(), const NetWidget()];

  @override
  void initState() {
    tabsList = [
      const Tab(child: Text("Log")),
      Tab(
        child: ValueListenableBuilder<int>(
          valueListenable: LoggerNet.length,
          builder: (context, _, __) {
            final errors = LoggerNet.list.where((n) => n.isError).length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Net"),
                if (errors > 0) ...[
                  const SizedBox(width: 6),
                  _ErrorBadge(count: errors),
                ],
              ],
            );
          },
        ),
      ),
    ];

    if (widget.dbFuture != null) {
      tabsList.add(
        const Tab(child: Text("SQLite", textAlign: TextAlign.center)),
      );

      tabsViewsList.add(DBWidget(dbFuture: widget.dbFuture));
    }

    if (widget.sheredPrefs != null) {
      tabsList.add(const Tab(child: Text("Prefs")));

      tabsViewsList.add(SharedPrefsWidget(sheredPrefs: widget.sheredPrefs));
    }

    tabsController = TabController(length: tabsList.length, vsync: this);
    tabsController.addListener(() {
      if (!tabsController.indexIsChanging) {
        switch (tabsController.index) {
          case 0:
            if (widget.onSelectFirstTab != null) {
              widget.onSelectFirstTab!();
            }
            break;
          case 1:
            if (widget.onSelectSecondTab != null) {
              widget.onSelectSecondTab!();
            }
            break;
          case 2:
            if (widget.onSelectThirdTab != null) {
              widget.onSelectThirdTab!();
            }
            break;
          default:
            if (widget.onSelectFourthTab != null) {
              widget.onSelectFourthTab!();
            }
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: letLogThemeMode,
      builder: (context, mode, _) {
        final Brightness sys =
            MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;
        final Brightness b = mode == ThemeMode.system
            ? sys
            : (mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
        final theme = _LetLogTheme.resolve(b, accent);
        return _LetLogScope(
          theme: theme,
          child: Scaffold(
            backgroundColor: theme.surface,
            appBar: AppBar(
              backgroundColor: theme.chrome,
              foregroundColor: theme.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 0,
              title: TabBar(
                controller: tabsController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tabsList,
                labelColor: theme.accent,
                unselectedLabelColor: theme.textMuted,
                indicatorColor: theme.accent,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Alternar tema',
                  icon: Icon(
                    b == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () {
                    letLogThemeMode.value = b == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                  },
                ),
              ],
            ),
            body: TabBarView(
              controller: tabsController,
              children: tabsViewsList,
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<TabController>('tabsController', tabsController),
    );
  }
}

class LoggerLog {
  static final List<LoggerLog> list = [];
  static final ValueNotifier<int> length = ValueNotifier(0);
  static final Map<Object, Object> _map = {};

  final _Type? type;
  final String? message;
  final String? detail;
  final DateTime? start;
  String? id;
  bool showDetail = false;
  LoggerLog({this.type, this.message, this.detail, this.start, this.id});

  String get typeName {
    return _printNames[type!.index];
  }

  String get tabName {
    return _tabNames[type!.index];
  }

  String get label {
    return _getTabName(type!.index).toUpperCase();
  }

  String get origin {
    final match = _originReg.firstMatch(message ?? "");
    return match?.group(1) ?? "App";
  }

  String get displayMessage {
    final match = _originReg.firstMatch(message ?? "");
    return match?.group(2)?.trim().isNotEmpty == true
        ? match!.group(2)!.trim()
        : message ?? "";
  }

  int get tabLevel {
    return _tabLevel[type!.index];
  }

  bool contains(String keyword) {
    if (keyword.isEmpty) return true;
    final normalizedKeyword = keyword.toLowerCase();
    return message != null &&
            message!.toLowerCase().contains(normalizedKeyword) ||
        detail != null && detail!.toLowerCase().contains(normalizedKeyword);
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

  static void add(
    _Type type,
    Object time,
    Object value,
    Object? detail,
    String timeColor,
    String msgColor,
  ) {
    final log = LoggerLog(
      type: type,
      message: value.toString(),
      detail: detail?.toString(),
      start: DateTime.now(),
    );
    list.add(log);
    _clearWhenTooMuch();
    length.value = list.length;
    if (Logger.config.printLog) {
      final detailText = log.detail == null || log.detail == 'null'
          ? ''
          : ' ${log.detail}';
      if (kIsWeb)
        debugPrint(
          '${log.typeName} $time${log.message}$detailText\n--------------------------------',
        );
      else {
        dev.log(
          '${log.typeName} $timeColor$time$msgColor${log.message}\x1B[0m$detailText\n--------------------------------',
          level: log.tabLevel,
          time: DateTime.now(),
        );
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
      LoggerLog.add(
        _Type.log,
        'DateTime.now()',
        '$key: $spend ms',
        null,
        '\x1B[37m',
        '\x1B[34m',
      );
    }
  }

  static void clear() {
    list.clear();
    _map.clear();
    length.value = 0;
  }
}

class LoggerNet extends ChangeNotifier {
  static const all = "All";
  static final List<LoggerNet> list = [];
  static final ValueNotifier<int> length = ValueNotifier(0);
  static final Map<String, LoggerNet> _map = {};
  static final List<String> types = [all];
  static final ValueNotifier<int> typeLength = ValueNotifier(1);

  final String? api;
  final String? req;
  final DateTime? start;
  String? id;
  String? type;
  int status = 100;
  int spend = 0;
  String? res;
  String? reqHeaders;
  String? resHeaders;
  bool showDetail = false;
  int _reqSize = -1;
  int _resSize = -1;

  LoggerNet({
    this.api,
    this.type,
    this.req,
    this.reqHeaders,
    this.resHeaders,
    this.start,
    this.res,
    this.spend = 0,
    this.status = 100,
    this.id,
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
    final normalizedKeyword = keyword.toLowerCase();
    return api != null && api!.toLowerCase().contains(normalizedKeyword) ||
        req != null && req!.toLowerCase().contains(normalizedKeyword) ||
        res != null && res!.toLowerCase().contains(normalizedKeyword);
  }

  bool get isError {
    return status >= 400 || (status >= 300 && status != 304);
  }

  bool get isPending {
    return status < 200;
  }

  String get errorMessage {
    if (!isError) return "";
    return _safePreview(_extractResponseMessage(res), maxLength: 260);
  }

  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.writeln("[$status] $api");
    sb.writeln();
    sb.writeln("Start: $start");
    sb.writeln("Spend: $spend ms");
    sb.writeln("Req Headers: $reqHeaders");
    sb.writeln();
    sb.writeln("Request: $req");
    sb.writeln();
    sb.writeln("Res Headers: $resHeaders");
    sb.writeln();
    sb.writeln("Response: $res");
    return sb.toString();
  }

  static void request(
    String api,
    String type,
    int status,
    Object? data,
    Object? headers,
    String msgColor,
  ) {
    final net = LoggerNet(
      api: api,
      type: type,
      status: status,
      reqHeaders: headers?.toString(),
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
          '${_printNames[4]} ${DateTime.now()} ${'$type: '}${net.api}${net.req == null ? '' : ' Headers: ${net.reqHeaders}\nData: ${net.req}'}\n--------------------------------',
        );
      else
        dev.log(
          '${_printNames[4]} (${DateTime.now()}) ${'$type: '}\x1B[103m\x1B[30m${net.api}\x1B[0m${net.req == null ? '' : ' Headers: ${net.reqHeaders}\nData: $msgColor${net.req}\x1B[0m'}\n--------------------------------',
          time: DateTime.now(),
        );
    }
  }

  static void _clearWhenTooMuch() {
    if (list.length > Logger.config.maxLimit) {
      list.removeRange(0, (Logger.config.maxLimit * 0.2).ceil());
    }
  }

  static void response(
    String api,
    int status,
    Object? data,
    Object? headers,
    String? type,
    String msgColor,
  ) {
    LoggerNet? net = _map[api];
    if (net != null) {
      _map.remove(api);
      net.spend = DateTime.now().difference(net.start!).inMilliseconds;
      net.status = status;
      net.resHeaders = headers?.toString();
      net.res = data?.toString();
      length.notifyListeners();
    } else {
      net = LoggerNet(api: api, start: DateTime.now(), type: type);
      net.status = status;
      net.resHeaders = headers?.toString();
      net.res = data?.toString();
      list.add(net);
      if (type != null && type != "" && !types.contains(type)) {
        types.add(type);
        typeLength.value++;
      }
      _clearWhenTooMuch();
      length.value++;
    }
    if (Logger.config.printNet) {
      if (kIsWeb)
        debugPrint(
          '${_printNames[5]} ${DateTime.now()} ${net.type == null ? '' : '${net.type}: '}{net.api}${net.res == null ? '' : ' Headers: ${net.resHeaders}\nData: ${net.res}'}\nSpend: ${net.spend} ms\n--------------------------------',
        );
      else
        dev.log(
          '${_printNames[5]} (${DateTime.now()}) ${net.type == null ? '' : '${net.type}: '}\x1B[106m\x1B[30m${net.api}\x1B[0m${net.res == null ? '' : ' Headers: ${net.resHeaders}\nData: $msgColor${net.res}\x1B[0m'}\nSpend: ${net.spend} ms\n--------------------------------',
          time: DateTime.now(),
        );
    }
  }

  static void clear() {
    list.clear();
    _map.clear();
    length.value = 0;
  }
}
