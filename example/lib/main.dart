import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:let_log/let_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Seed a few sample values so the Shared Prefs tab has content to show.
  await prefs.setString('username', 'yung');
  await prefs.setBool('darkMode', true);
  await prefs.setInt('launchCount', 3);
  await prefs.setDouble('volume', 0.8);
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      // theme: ThemeData.dark(),
      home: MyHomePage(prefs: prefs),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SharedPreferences>('prefs', prefs));
  }
}

class MyHomePage extends StatefulWidget {
  final SharedPreferences prefs;

  const MyHomePage({super.key, required this.prefs});

  @override
  _MyHomePageState createState() => _MyHomePageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SharedPreferences>('prefs', prefs));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    // setting
    // Logger.enabled = false;
    // Logger.config.maxLimit = 50;
    // Logger.config.reverse = true;
    // Logger.config.printLog = false;
    // Logger.config.printNet = false;

    _test(null);
    Timer.periodic(const Duration(seconds: 5), _test);
    super.initState();
  }

  void _test(_) {
    // log
    Logger.log('(${DateTime.now()})', "this is log");

    // debug
    Logger.debug(
      '(${DateTime.now()})',
      "this is debug",
      detail: "this is debug message",
    );

    // warn
    Logger.warn(
      '(${DateTime.now()})',
      "this is warn",
      detail: "this is a warning message",
    );

    // error
    Logger.error(
      '(${DateTime.now()})',
      "this is error",
      detail: "this is a error message",
    );

    // test error — a caught exception logged with its stack trace in `detail`,
    // so it renders as a single card with a collapsible stack-trace section.
    try {
      final test = {};
      test["test"]["test"] = 1;
    } catch (a, e) {
      Logger.error('(${DateTime.now()})', a, detail: e);
    }

    // time test
    Logger.time("timeTest");
    Logger.endTime("timeTest");

    // log net work
    Logger.net("api/user/getUser", data: {"user": "yung", "pass": "xxxxxx"});
    Logger.endNet(
      "api/user/getUser",
      data: {
        "users": [
          {"id": 1, "name": "yung", "avatar": "xxx"},
          {"id": 2, "name": "yung2", "avatar": "xxx"},
        ],
      },
    );

    // log net work
    Logger.net("ws/chat/getList", data: {"chanel": 1}, type: "Socket");
    Logger.endNet(
      "ws/chat/getList",
      data: {
        "users": [
          {"id": 1, "name": "yung", "avatar": "xxx"},
          {"id": 2, "name": "yung2", "avatar": "xxx"},
        ],
      },
    );

    // clear log
    // Logger.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Logger(sheredPrefs: widget.prefs);
  }
}
