import 'dart:math' as m;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pvm_col/functions.dart';
import 'package:pvm_col/widgets/base.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/ControlScreen.dart';
import 'data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 이렇게 하면 앱이 실행되기 전에 데이터를 모두 가져올 수 있어서 오류가 나지 않는다.
  prefs = await SharedPreferences.getInstance();
  return runApp(const PortableVNAMonitorApp());
}

class PortableVNAMonitorApp extends StatelessWidget {
  const PortableVNAMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    baseSize =
        m.sqrt((size.width * size.width) + (size.height * size.height)) * 0.01;
    return const MaterialApp(
      home: PortableVNAMonitor(),
    );
  }
}

class PortableVNAMonitor extends StatefulWidget {
  const PortableVNAMonitor({super.key});

  @override
  PortableVNAMonitorState createState() => PortableVNAMonitorState();
}

class PortableVNAMonitorState extends State<PortableVNAMonitor> {
  @override
  void initState() {
    super.initState();

    WakelockPlus.enable(); // 화면 꺼짐 방지

    checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(([DeviceOrientation.portraitUp]));
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            margin(3), // Galaxy S23 Plus - 3 / Galaxy Tab S9 - 2
            const Expanded(
              flex: 15,
              child: ControlScreen(),
            ),
            // const Expanded(
            //   flex: 10,
            //   child: twoGraphScreen(),
            // ),
            // const Expanded(
            //   flex: 1,
            //   child: Choosefilescreen(),
            // ),
            // const Expanded(
            //   flex: 5,
            //   child: Onegraphscreen(),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    WakelockPlus.disable();
  }
}
