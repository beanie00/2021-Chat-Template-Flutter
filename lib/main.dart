// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:dearplant/screens/splash.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_blue/flutter_blue.dart';

// import 'const.dart';
// import 'login.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'DEAR PLANT',
//       theme: ThemeData(
//         primaryColor: themeColor,
//       ),
//       home: SplashScreen(),
//       //home: LoginScreen(title: 'DEAR PLANT'),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
import 'package:dearplant/screens/splash.dart';
import 'package:dearplant/screens/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

import 'screens/bluetooth_off_screen.dart';

String gSerialMessages = '';
int gIndex = 0;
double gValue = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.white,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if ((state == BluetoothState.on) || (kDebugMode)) {
              return SplashScreen();
              // return FindDevicesScreen(); // example code
            }
            return BluetoothOffScreen();
          }),
    );
  }
}
