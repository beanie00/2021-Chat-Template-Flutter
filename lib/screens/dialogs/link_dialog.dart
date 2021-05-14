import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dearplant/ble_example_widgets.dart';
import 'package:dearplant/constants/app_colors.dart';
import 'package:dearplant/constants/music_theme.dart';
import 'package:dearplant/controllers/app_data.dart';
import 'package:dearplant/controllers/http_controller.dart';
import 'package:dearplant/controllers/sound_controller.dart';
import 'package:dearplant/models/music_theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:get/get.dart';
import 'package:dearplant/home.dart';

import '../../const.dart';
import '../../home.dart';
import '../../login.dart';

String moistureString = '';
int moistureInt = 0;
int countOfLinefeed = 0;
String deviceName = '';

//BluetoothDevice gConnectedDevice;
//BluetoothCharacteristic gConnectedCharacteristic;

class LinkDialog extends StatefulWidget {
  LinkDialog();

  @override
  _LinkDialogState createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  @override
  Widget build(BuildContext context) {
    FlutterBlue.instance.stopScan();
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 4));
    return SimpleDialog(
      title: Row(
        children: [
          Text('B612 연결'),
          Spacer(),
          IconButton(
            icon: Icon(
              Icons.cancel_outlined,
              color: Colors.red,
            ),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
      children: [
        StreamBuilder<List<ScanResult>>(
          stream: FlutterBlue.instance.scanResults,
          initialData: [],
          builder: (c, snapshot) {
            return Column(
              children: snapshot.data
                  .map(
                    (r) => ScanResultTile(
                      result: r,
                      onTap: () async {
                        Get.back();
                        Future.delayed(Duration(seconds: 1))
                            .then((value) async {
                          Get.dialog(
                            AlertDialog(
                              contentPadding:
                                  EdgeInsets.all(Get.size.width / 3),
                              content: AspectRatio(
                                aspectRatio: 1,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.purple),
                                ),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            barrierDismissible: true,
                          );
                          deviceName = r.device.name;
                          gConnectedDevice = r.device;
                          gConnectedDevice?.state
                              .listen((BluetoothDeviceState event) {
                            if (event == BluetoothDeviceState.disconnected) {
                              Get.find<AppData>().isConnected = false;
                              Get.find<AppData>().isMusicPlaying = false;
                              Get.find<AppData>().isMuted = false;
                              SoundController.stop();
                            }
                          });

                          await r.device.connect();
                          await r.device.discoverServices();
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(fireUserUid)
                              .collection('PlantInventory')
                              .get()
                              .then((QuerySnapshot ds) {
                            ds.docs.forEach((doc) => setB612(doc));
                          });
                          r.device.services
                              .listen((List<BluetoothService> event) {
                            // if (Get.find<AppData>().isConnected) {
                            //   return;
                            // }
                            event.forEach((BluetoothService element) async {
                              print(
                                  '${element.uuid.toString().toUpperCase().substring(4, 8)}');
                              if ((element.uuid
                                      .toString()
                                      .toUpperCase()
                                      .substring(4, 8)) ==
                                  'FFE0') {
                                Get.find<AppData>().isConnected = true;
                                BluetoothCharacteristic c =
                                    element.characteristics.first;
                                await c.setNotifyValue(true);
                                await c.read();
                                gConnectedCharacteristic = c;
                                Timer.periodic(
                                    Duration(milliseconds: 50), _timerCallback);
                                moistureString = '';
                                moistureInt = 0;
                                countOfLinefeed = 0;
                                c.value.listen(_bluetoothReceiveCallback);
                              }
                            });
                          });
                          Get.back();
                        });
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
      contentPadding: EdgeInsets.symmetric(vertical: 50),
    );
  }
}

void setB612(DocumentSnapshot document) {
  print('setB612' + document['plantNick']);
  print('selectedPlantNick' + selectedPlantNick);
  if (document['plantNick'] == selectedPlantNick) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(fireUserUid)
        .collection('PlantInventory')
        .doc(document['plantNick'])
        .update({
      'B612': deviceName,
    });
  } else {
    FirebaseFirestore.instance
        .collection('users')
        .doc(fireUserUid)
        .collection('PlantInventory')
        .doc(document['plantNick'])
        .update({
      'B612': "",
    });
  }
}

void _bluetoothReceiveCallback(value) {
  AppData appData = Get.find<AppData>();
  value.forEach((element) {
    if ((48 <= element) && (element <= 57)) {
      // ascii 0~9, moisture data
      print("moistureString2: " + moistureString);
      moistureString += String.fromCharCode(element);
      if (moistureString.length == 3) {
        MusicThemeModel newMusic;
        moistureInt = int.parse(moistureString);
        print('moisture2: $moistureInt');
        print('email2: ' + prefs.getString('nickname'));
        print('nickname2: ' + selectedPlantNick);

        // 1. 수분값 매핑
        double moisturePercent = 1 - ((moistureInt - 100) / 400);

        HttpController.sendMoistureToServer(
            moisture: (moisturePercent * 100).toString(),
            email: prefs.getString('nickname'),
            nick: selectedPlantNick);

        FirebaseFirestore.instance
            .collection('users')
            .doc(fireUserUid)
            .collection('PlantInventory')
            .doc(selectedPlantNick)
            .update({
          'watering': (moisturePercent * 100).toStringAsFixed(1) + "%",
        });

        if (appData.isMuted) {
          return;
        }

        // 2. 0~25: 모닥불, 25~50: 귀뚜라미, 50~75: 새소리, 75~100: 강물
        if (moisturePercent < 0.25) {
          newMusic = MusicThemes.fire;
        } else if (moisturePercent < 0.5) {
          newMusic = MusicThemes.cricket;
        } else if (moisturePercent < 0.75) {
          newMusic = MusicThemes.bird;
        } else {
          newMusic = MusicThemes.river;
        }
        Get.find<AppData>().selectedMusic = newMusic;
        SoundController.changeMusic(newMusic);
      }
    } else if ((0 <= element) && (element < 20)) {
      // int 0~20, touch data

      if (element >= 10) {
        var now = DateTime.now();
        if (now.difference(touch_time).inMinutes >= 5) {
          HttpController.sendTouchEvent(
              email: prefs.getString('nickname'), nick: wateringPlant);
          touch_time = DateTime.now();
        }
      }

      if (countOfLinefeed < 2) {
        // exception: linefeed & carrige return value
        countOfLinefeed++;
        return;
      }

      value = element.toDouble();

      double touchValue =
          (value / 20).clamp(0, 1); // 0 ~ 20 -> Normalization 0 ~ 1
      gDelayedVolume = touchValue;
      if (touchValue > 0.1) {
        if (appData.isMusicPlaying == false) {
          appData.isMusicPlaying = true;
          SoundController.play();
        }
      }
      print('$touchValue, ${appData.isMusicPlaying}');
    } else {
      // error data
    }

    // double value = element.toDouble();
    // element.toString()
    // if (value > 20) {
    // print('${element.toString()}}');
    // return;
    // }
  });
  return;
}

void _timerCallback(timer) async {
  if (gConnectedDevice == null) {
  } else {
    SoundController.setVolume(gDelayedVolume);
    // }
  }
}
