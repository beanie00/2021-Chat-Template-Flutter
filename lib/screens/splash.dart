import 'dart:async';

import 'package:dearplant/constants/app_colors.dart';
import 'package:dearplant/controllers/app_data.dart';
import 'package:dearplant/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final appData = Get.put<AppData>(AppData(), permanent: true);

  @override
  void initState() {
    Timer(Duration(seconds: 2), () async {
      Get.off(
        LoginScreen(),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width / 2.5,
          child: Image.asset('assets/images/dearplant_white.webp'),
        ),
      ),
    );
  }
}
