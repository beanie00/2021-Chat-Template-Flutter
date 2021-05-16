import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dearplant/screens/dialogs/link_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dearplant/chat.dart';
import 'package:dearplant/const.dart';
import 'package:dearplant/settings.dart';
import 'package:dearplant/screens/home_screen.dart';
import 'package:dearplant/widget/loading.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_colors.dart';
import 'constants/app_colors.dart';
import 'constants/music_theme.dart';
import 'controllers/app_data.dart';
import 'controllers/http_controller.dart';
import 'controllers/sound_controller.dart';
import 'login.dart';
import 'main.dart';
import 'models/music_theme_model.dart';

var selectedPlantNick = '';
var wateringPlant = '';
var touch_time = DateTime.utc(2021, DateTime.april, 30);
BluetoothDevice gConnectedDevice;
BluetoothCharacteristic gConnectedCharacteristic;
SharedPreferences prefs;

class HomeScreen extends StatefulWidget {
  final String currentUserId;

  HomeScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => HomeScreenState(currentUserId: currentUserId);
}

class HomeScreenState extends State<HomeScreen> {
  HomeScreenState({Key key, @required this.currentUserId});

  final String currentUserId;
  //final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  int _limitIncrement = 20;
  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: '식물 등록', icon: Icons.add),
    //const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    //registerNotification();
    //configLocalNotification();
    readLocal();
    HttpController.getPlantNameAll();
    listScrollController.addListener(scrollListener);
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('PlantInventory')
        .get()
        .then((QuerySnapshot ds) {
      ds.docs.forEach((doc) => linkB612(doc));
    });
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
  }

  void linkB612(DocumentSnapshot document) {
    if (document['B612'] != "") {
      wateringPlant = document['plantNick'];
      FlutterBlue flutterBlue = FlutterBlue.instance;
      flutterBlue.startScan(timeout: Duration(seconds: 4));
      // Listen to scan results
      flutterBlue.scanResults.listen((results) {
        // do something with scan results
        for (ScanResult r in results) {
          if (r.device.name == document['B612']) {
            gConnectedDevice = r.device;
            r.device.connect();
            r.device.discoverServices();
            r.device.services.listen((List<BluetoothService> event) {
              // if (Get.find<AppData>().isConnected) {
              //   return;
              // }
              event.forEach((BluetoothService element) async {
                print(
                    '${element.uuid.toString().toUpperCase().substring(4, 8)}');
                if ((element.uuid.toString().toUpperCase().substring(4, 8)) ==
                    'FFE0') {
                  BluetoothCharacteristic c = element.characteristics.first;
                  await c.setNotifyValue(true);
                  await c.read();
                  gConnectedCharacteristic = c;
                  Timer.periodic(Duration(milliseconds: 50), _timerCallback);
                  moistureString = '';
                  moistureInt = 0;
                  countOfLinefeed = 0;
                  c.value.listen(_bluetoothReceiveCallback);
                }
              });
            });
          }
        }
      });
    }
  }

  void _bluetoothReceiveCallback(value) {
    AppData appData = Get.find<AppData>();
    value.forEach((element) {
      //_showNotification();
      //print("element: " + element);
      if ((48 <= element) && (element <= 57)) {
        // ascii 0~9, moisture data
        moistureString += String.fromCharCode(element);
        print("moistureString: " + moistureString);
        if (moistureString.length == 3) {
          MusicThemeModel newMusic;
          moistureInt = int.parse(moistureString);
          print('moisture: $moistureInt');
          print('email: ' + prefs.getString('nickname'));
          print('nickname: ' + wateringPlant);

          // 1. 수분값 매핑
          double moisturePercent = 1 - ((moistureInt - 100) / 400);

          HttpController.sendMoistureToServer(
              moisture: (moisturePercent * 100).toString(),
              email: prefs.getString('nickname'),
              nick: wateringPlant);

          FirebaseFirestore.instance
              .collection('users')
              .doc(fireUserUid)
              .collection('PlantInventory')
              .doc(wateringPlant)
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

  // void registerNotification() {
  //   firebaseMessaging.requestNotificationPermissions();

  //   firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
  //     print('onMessage: $message');
  //     Platform.isAndroid
  //         ? showNotification(message['notification'])
  //         : showNotification(message['aps']['alert']);
  //     return;
  //   }, onResume: (Map<String, dynamic> message) {
  //     print('onResume: $message');
  //     return;
  //   }, onLaunch: (Map<String, dynamic> message) {
  //     print('onLaunch: $message');
  //     return;
  //   });

  //   firebaseMessaging.getToken().then((token) {
  //     print('token: $token');
  //     FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(currentUserId)
  //         .update({'pushToken': token});
  //   }).catchError((err) {
  //     Fluttertoast.showToast(msg: err.message.toString());
  //   });
  // }

  // void configLocalNotification() {
  //   var initializationSettingsAndroid =
  //       new AndroidInitializationSettings('app_icon');
  //   var initializationSettingsIOS = new IOSInitializationSettings();
  //   var initializationSettings = new InitializationSettings(
  //       initializationSettingsAndroid, initializationSettingsIOS);
  //   flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => RegisterPlant()));
    }
  }

//   void showNotification(message) async {
//     var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
//       Platform.isAndroid ? 'com.dfa.' : 'com.dearplant.dearplant_link',
//       'Flutter chat demo',
//       'your channel description',
//       playSound: true,
//       enableVibration: true,
//       importance: Importance.Max,
//       priority: Priority.High,
//     );
//     var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
//     var platformChannelSpecifics = new NotificationDetails(
//         androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

//     print(message);
// //    print(message['body'].toString());
// //    print(json.encode(message));

//     await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
//         message['body'].toString(), platformChannelSpecifics,
//         payload: json.encode(message));

// //    await flutterLocalNotificationsPlugin.show(
// //        0, 'plain title', 'plain body', platformChannelSpecifics,
// //        payload: 'item x');
//   }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> settingPlant(DocumentSnapshot document) async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  AppData appData = Get.find<AppData>();
                  if (gConnectedDevice != null) {
                    gConnectedDevice.disconnect();
                  }
                  appData.isMuted = false;
                  appData.isMusicPlaying = false;
                  SoundController.stop();
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(fireUserUid)
                      .collection('PlantInventory')
                      .doc(document['plantNick'])
                      .update({
                    'B612': "",
                  });
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'B612 연결 끊기',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  //deletePlant();
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      '식물 삭제',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      '닫기',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.purple,
          automaticallyImplyLeading: false,
          toolbarHeight: 55,
          title: Image.asset('assets/images/dearplant_white.webp',
              height: 37, fit: BoxFit.contain),
          // Text(
          //   '나의 식물 친구',
          //   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          // ),
          centerTitle: true,
          leading: null,
          actions: <Widget>[
            new IconButton(
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => RegisterPlant())),
            ),
          ]

          // <Widget>[
          //   PopupMenuButton<Choice>(
          //     onSelected: onItemMenuPress,
          //     itemBuilder: (BuildContext context) {
          //       return choices.map((Choice choice) {
          //         return PopupMenuItem<Choice>(
          //             value: choice,
          //             child: Row(
          //               children: <Widget>[
          //                 Icon(
          //                   choice.icon,
          //                   color: primaryColor,
          //                 ),
          //                 Container(
          //                   width: 10.0,
          //                 ),
          //                 Text(
          //                   choice.title,
          //                   style: TextStyle(color: primaryColor),
          //                 ),
          //               ],
          //             ));
          //       }).toList();
          //     },
          //   ),
          // ],
          ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            //List
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("images/main2.jpg"),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5), BlendMode.multiply)),
              ),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('PlantInventory')
                    .limit(_limit)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: double.infinity,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      RegisterPlant())), // handle your image tap here
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Image.asset("assets/images/register_plant.png",
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    height:
                                        MediaQuery.of(context).size.width / 3,
                                    fit: BoxFit.contain),
                                SizedBox(height: 10),
                                Text(
                                  '식물 친구 등록하기',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ]),
                        ));
                  } else {
                    if (snapshot.data.docs.length == 0) {
                      return Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: double.infinity,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        RegisterPlant())), // handle your image tap here
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Image.asset(
                                      "assets/images/register_plant.png",
                                      width:
                                          MediaQuery.of(context).size.width / 3,
                                      height:
                                          MediaQuery.of(context).size.width / 3,
                                      fit: BoxFit.contain),
                                  SizedBox(height: 10),
                                  Text(
                                    '식물 친구 등록하기',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13),
                                  ),
                                ]),
                          ));
                      // child: Center(
                      //     child: );
                    } else {
                      return Column(
                        children: [
                          SizedBox(height: 15),
                          Text(
                            '나의 식물 친구',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          SizedBox(height: 5),
                          Expanded(
                              child: ListView.builder(
                            padding: EdgeInsets.all(10.0),
                            itemBuilder: (context, index) => buildItem(
                                context, snapshot.data.docs[index], index),
                            itemCount: snapshot.data.docs.length,
                            controller: listScrollController,
                          )),
                          // Column(
                          //     mainAxisAlignment: MainAxisAlignment.end,
                          //     crossAxisAlignment: CrossAxisAlignment.stretch,
                          //     children: [
                          //       Image.asset("assets/images/register_plant.png",
                          //           width:
                          //               MediaQuery.of(context).size.width / 4,
                          //           height:
                          //               MediaQuery.of(context).size.width / 4,
                          //           fit: BoxFit.contain),
                          //       SizedBox(height: 10),
                          //       Text(
                          //         '식물 친구 등록하기',
                          //         textAlign: TextAlign.center,
                          //         style: TextStyle(
                          //             color: Colors.white, fontSize: 13),
                          //       ),
                          //       SizedBox(height: 10)
                          //     ]),
                        ],
                      );
                    }
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: isLoading ? const Loading() : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document, int index) {
    String friendDay = "";
    if (document.get('date_registered') != null) {
      final dateRegistered = document.get('date_registered').toDate();
      final today = DateTime.now();
      friendDay = (today.difference(dateRegistered).inDays + 1).toString();
    }

    return GestureDetector(
        onLongPress: () {
          settingPlant(document);
        },
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Container(
            child: Column(
              children: [
                Row(
                  children: <Widget>[
                    Column(
                      children: [
                        Material(
                          child: document.get('plantUrl') != null
                              ? CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          themeColor),
                                    ),
                                    width: 100.0,
                                    height: 100.0,
                                    padding: EdgeInsets.all(15.0),
                                  ),
                                  imageUrl: document.get('plantUrl'),
                                  width: 100.0,
                                  height: 100.0,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.account_circle,
                                  size: 100.0,
                                  color: greyColor,
                                ),
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        Container(
                          child: Text(
                            document.get('plantNick'),
                            style: TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                          padding: EdgeInsets.only(top: 5),
                        ),
                        // document.get('B612') == ""
                        //     ? Container(
                        //         margin: EdgeInsets.only(top: 2),
                        //         padding: EdgeInsets.only(
                        //             top: 3, bottom: 3, left: 5, right: 5),
                        //         child: Text(
                        //           '',
                        //           style: TextStyle(
                        //             fontSize: 10,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       )
                        //     : Container(
                        //         margin: EdgeInsets.only(top: 2),
                        //         padding: EdgeInsets.only(
                        //             top: 3, bottom: 3, left: 5, right: 5),
                        //         decoration: BoxDecoration(
                        //           color: AppColors.green,
                        //           borderRadius:
                        //               BorderRadius.all(Radius.circular(25.0)),
                        //         ),
                        //         child: Text(
                        //           document.get('B612'),
                        //           style: TextStyle(
                        //             fontSize: 10,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ),
                      ],
                    ),
                    Flexible(
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: Text(
                                document.get('plantName') ?? 'Not available',
                                style: TextStyle(
                                    color: AppColors.purple, fontSize: 15),
                              ),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                            ),
                            friendDay != ""
                                ? Container(
                                    child: Text(
                                      '친구된지 ' + friendDay + '일',
                                      style: TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 15),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    margin: EdgeInsets.fromLTRB(
                                        10.0, 0.0, 0.0, 0.0),
                                  )
                                : Container(),
                            document.get('B612') != ""
                                ? Container(
                                    child: Text(
                                      '수분량 : ${document.get('watering')}',
                                      style: TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 15),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    margin: EdgeInsets.fromLTRB(
                                        10.0, 0.0, 0.0, 0.0),
                                  )
                                : Container(),
                            document.get('B612') == ""
                                ? Container()
                                : Align(
                                    child: TextButton(
                                      child: Text(
                                        document.get('B612'),
                                        style: TextStyle(
                                            color: AppColors.purple,
                                            fontSize: 10),
                                        //textAlign: TextAlign.center,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        //alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.only(
                                            top: 1,
                                            bottom: 1,
                                            left: 15,
                                            right: 15),
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                        ),
                                      ),
                                      onPressed: null,
                                    ),
                                    alignment: Alignment.centerLeft,
                                  )
                          ],
                        ),
                        margin: EdgeInsets.only(left: 20.0),
                      ),
                    ),
                  ],
                ),
                document.get('B612') == ""
                    ? SizedBox(height: 5)
                    : SizedBox(height: 20),
                document.get('B612') == ""
                    ? TextButton(
                        onPressed: () {
                          selectedPlantNick = document.get('plantNick');
                          Get.dialog(
                            LinkDialog(),
                            barrierDismissible: false,
                          );
                        },
                        child: Text(
                          'B612 연결',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.only(
                              top: 10, bottom: 10, left: 40, right: 40),
                          backgroundColor: AppColors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40.0),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                            Flexible(
                                child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Chat(
                                              peerId: document.get('plantNick'),
                                              peerAvatar:
                                                  document.get('plantUrl'),
                                            )));
                              },
                              child: Text(
                                '식물과 수다 떨기',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13.0),
                                textAlign: TextAlign.center,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.only(
                                    top: 3, bottom: 3, left: 15, right: 15),
                                backgroundColor: AppColors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.0),
                                ),
                              ),
                            )),
                            Flexible(
                                child: TextButton(
                              onPressed: () {
                                document.get('B612') == ""
                                    ? Fluttertoast.showToast(
                                        msg: "B612를 먼저 연결해주세요.")
                                    : Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PlantSound()));
                              },
                              child: Text(
                                '식물과 자연 소리 듣기',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13.0),
                                textAlign: TextAlign.center,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.only(
                                    top: 3, bottom: 3, left: 15, right: 15),
                                backgroundColor: AppColors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.0),
                                ),
                              ),
                            )),
                          ])
              ],
            ),
            padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
            // shape:
            //     RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
        ));
  }
}

class Choice {
  const Choice({@required this.title, @required this.icon});

  final String title;
  final IconData icon;
}

// Future _showNotification() async {
//   var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
//       'your channel id', 'your channel name', 'your channel description',
//       importance: Importance.max, priority: Priority.high);
//   var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
//   var platformChannelSpecifics = new NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//       iOS: iOSPlatformChannelSpecifics);
//   await flutterLocalNotificationsPlugin.show(
//     0,
//     'New Notification',
//     'Flutter is awesome',
//     platformChannelSpecifics,
//     payload: 'This is notification detail Text...',
//   );
// }
