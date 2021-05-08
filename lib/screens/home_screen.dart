import 'dart:convert';
import 'dart:ui';

import 'package:dearplant/constants/app_colors.dart';
import 'package:dearplant/constants/music_theme.dart';
import 'package:dearplant/controllers/app_data.dart';
import 'package:dearplant/controllers/bluetooth_controller.dart';
import 'package:dearplant/controllers/sound_controller.dart';
import 'package:dearplant/screens/dialogs/link_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    gMusicThemeList.forEach((element) async {
      element.cachedImageWidgetHighQuality =
          AssetImage(element.imageHighQualityPath);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이미지가 커서 0.5초 딜레이 있어서, 고화질 사진만 미리 캐쉬함
    gMusicThemeList.forEach((element) async =>
        await precacheImage(element.cachedImageWidgetHighQuality, context));
  }

  final appData = Get.put<AppData>(AppData(), permanent: true);
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppData>(
      builder: (appData) {
        return Container(
          color: AppColors.purple,
          child: SafeArea(
            bottom: false,
            child: Scaffold(
              backgroundColor: AppColors.purple,
              appBar: AppBar(
                centerTitle: true,
                toolbarHeight: 51,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Stack(
                  children: [
                    Center(),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: 51,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Image.asset(
                            'assets/images/dearplant_white.webp',
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                    ),
                    appData.isConnected
                        ? Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                              onPressed: () {
                                if (appData.isConnected) {
                                  gConnectedDevice!.disconnect();
                                  appData.isConnected = false;
                                  appData.isMuted = false;
                                  appData.isMusicPlaying = false;
                                  SoundController.stop();
                                } else {
                                  Get.dialog(
                                    LinkDialog(),
                                    barrierDismissible: false,
                                  );
                                }
                              },
                              child: Text(
                                'B612 연결 끊기',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          )
                        : Container(),
                    // Align(
                    //   alignment: Alignment.bottomRight,
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.end,
                    //     children: [
                    //       Icon(
                    //         Icons.bluetooth_disabled,
                    //         size: 20.0,
                    //         color: Colors.white,
                    //       ),
                    //       Switch(
                    //         activeColor: Colors.white,
                    //         value: appData.isConnected,
                    //         onChanged: (value) {
                    //           if (appData.isConnected) {
                    //             gConnectedDevice!.disconnect();
                    //             appData.isConnected = false;
                    //             appData.isMuted = false;
                    //             appData.isMusicPlaying = false;
                    //             SoundController.stop();
                    //           } else {
                    //             Get.dialog(
                    //               LinkDialog(),
                    //               barrierDismissible: false,
                    //             );
                    //           }
                    //         },
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // Align(
                    //   alignment: Alignment.bottomRight,
                    //   child: Text(
                    //     'B612 연결 끊기',
                    //     style: TextStyle(color: Colors.white, fontSize: 10),
                    //     textAlign: TextAlign.end,
                    //   ),
                    // ),
                  ],
                ),
              ),
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: appData.selectedMusic.cachedImageWidgetHighQuality,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5), BlendMode.darken),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 25,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: Container(),
                      flex: 1,
                    ),
                    Text(
                      '식물 친구를 통해 자연을 느껴보세요.',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    Text(
                      '식물 친구와의 인터랙션에 따라\n다양한 자연의 소리가 재생됩니다.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    (!appData.isConnected)
                        ? _connectButton()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _muteToggleButton(),
                              SizedBox(
                                width: 14,
                              ),
                              _calibrateButton(),
                            ],
                          ),
                    SizedBox(
                      height: 70,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 3.7,
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbColor: Colors.white.withOpacity(0.5),
                        radius: Radius.circular(10),
                        child: Stack(
                          children: [
                            ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: gMusicThemeList.length,
                              itemBuilder: (context, index) {
                                String image = gMusicThemeList[index].imagePath;
                                bool isSelected =
                                    (appData.selectedMusic.imagePath ==
                                        gMusicThemeList[index].imagePath);
                                return GestureDetector(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 4.5,
                                        color: isSelected
                                            ? AppColors.purple
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Image.asset(image),
                                  ),
                                  onTap: () {
                                    appData.selectedMusic =
                                        gMusicThemeList[index];
                                    SoundController.changeMusic(
                                        gMusicThemeList[index]);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(),
                      flex: 2,
                    ),
                    Text(
                      'Copyright 2021 Dearplants Inc. All rights reserved.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w200,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _muteToggleButton() {
    AppData appData = Get.find<AppData>();
    return TextButton(
      onPressed: () {
        if (appData.isMusicPlaying && appData.isMuted) {
          SoundController.play();
        } else {
          SoundController.stop();
        }
        appData.isMuted = !(appData.isMuted);
        SoundController.stop();
      },
      child: Text(
        appData.isMuted ? '소리 켜기' : '소리 끄기',
        style: TextStyle(color: AppColors.purple),
        textAlign: TextAlign.center,
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
      ),
    );
  }

  Widget _calibrateButton() {
    AppData appData = Get.find<AppData>();
    return TextButton(
      onPressed: () {
        if (gConnectedCharacteristic != null) {
          List<int> bytes = utf8.encode('recalibrate+water');
          gConnectedCharacteristic?.write(bytes);
        }
      },
      child: Text(
        '식물 기분 UP! 시키기',
        style: TextStyle(color: AppColors.purple),
        textAlign: TextAlign.center,
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
      ),
    );
  }

  Widget _connectButton() {
    return TextButton(
      onPressed: () {
        Get.dialog(
          LinkDialog(),
          barrierDismissible: false,
        );
      },
      child: Text(
        'B612 연결',
        style: TextStyle(color: AppColors.purple),
        textAlign: TextAlign.center,
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.only(top: 10, bottom: 10, left: 40, right: 40),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
      ),
    );
  }
}
