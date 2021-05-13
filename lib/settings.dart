import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:dearplant/const.dart';
import 'package:dearplant/login.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_colors.dart';
import 'controllers/http_controller.dart';

class RegisterPlant extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 55,
        backgroundColor: AppColors.purple,
        title: Text(
          '식물 등록',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;
  TextEditingController editingController = TextEditingController();
  final duplicateItems = plantNameAll;
  var items = List<String>();

  SharedPreferences prefs;

  String id = fireUserUid;
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';

  bool isLoading = false;
  File avatarImageFile;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
    //items.addAll(duplicateItems);
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();

    // Force refresh input
    setState(() {});
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);

    File image = File(pickedFile.path);

    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
    }
    uploadFile();
  }

  Future uploadFile() async {
    print("firebase_id : " + id);
    String plantId = FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection('PlantInventory')
        .snapshots()
        .length
        .toString();
    String fileName = plantId;
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(fileName);
    UploadTask uploadTask = ref.putFile(avatarImageFile);
    uploadTask.then((value) {
      value.ref.getDownloadURL().then((downloadUrl) {
        photoUrl = downloadUrl;
        Fluttertoast.showToast(msg: "식물 프로필 사진이 등록되었습니다.");
        setState(() {
          isLoading = false;
        });
      }, onError: (err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: '이미지 형식의 파일을 선택해주세요.');
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void handleUpdateData() {
    showNotification();
    // String plantId = FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(id)
    //     .collection('PlantInventory')
    //     .snapshots()
    //     .length
    //     .toString();
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });

    aboutMe = editingController.text;

    HttpController.registerPlant(
        nick: nickname, typename: aboutMe, email: prefs.getString('nickname'));

    FirebaseFirestore.instance
        .collection('users')
        .doc(fireUserUid)
        .collection('PlantInventory')
        .doc(nickname)
        .set({
      'plantNick': nickname,
      'plantName': aboutMe,
      'plantUrl': photoUrl,
      'watering': "데이터 없음",
      'date_registered': DateTime.now(),
      'B612': "",
    }).then((data) async {
      await prefs.setString('plantNick', nickname);
      await prefs.setString('plantName', aboutMe);
      await prefs.setString('plantUrl', photoUrl);
      await prefs.setString('watering', "");

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "새로운 식물 친구가 등록되었어요!");
      Navigator.pop(context);
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void filterSearchResults(String query) {
    List<String> dummySearchList = List<String>();
    dummySearchList.addAll(duplicateItems);
    if (query.isNotEmpty) {
      List<String> dummyListData = List<String>();
      dummySearchList.forEach((item) {
        if (item.contains(query)) {
          dummyListData.add(item);
        }
      });
      setState(() {
        items.clear();
        items.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        items.clear();
        items.addAll(duplicateItems);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Avatar
              Container(
                child: Center(
                  child: Stack(
                    children: <Widget>[
                      (avatarImageFile == null)
                          ? (photoUrl != ''
                              ? Material(
                                  child: CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                themeColor),
                                      ),
                                      width: 90.0,
                                      height: 90.0,
                                      padding: EdgeInsets.all(20.0),
                                    ),
                                    imageUrl: photoUrl,
                                    width: 90.0,
                                    height: 90.0,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(45.0)),
                                  clipBehavior: Clip.hardEdge,
                                )
                              : Icon(
                                  Icons.account_circle,
                                  size: 90.0,
                                  color: greyColor,
                                ))
                          : Material(
                              child: Image.file(
                                avatarImageFile,
                                width: 90.0,
                                height: 90.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(45.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: primaryColor.withOpacity(0.5),
                        ),
                        onPressed: getImage,
                        padding: EdgeInsets.all(30.0),
                        splashColor: Colors.transparent,
                        highlightColor: greyColor,
                        iconSize: 30.0,
                      ),
                    ],
                  ),
                ),
                width: double.infinity,
                margin: EdgeInsets.all(20.0),
              ),

              // Input
              Column(
                children: <Widget>[
                  // Username
                  Container(
                    child: Text(
                      '식물 별명',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.purple),
                    ),
                    margin: EdgeInsets.only(left: 10.0, bottom: 5.0, top: 10.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: primaryColor),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '반려식물의 별명을 지어주세요.',
                          contentPadding: EdgeInsets.all(5.0),
                          hintStyle: TextStyle(color: greyColor),
                        ),
                        controller: controllerNickname,
                        onChanged: (value) {
                          nickname = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  ),

                  // About me
                  Container(
                    child: Text(
                      '식물 종 선택',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.purple),
                    ),
                    margin: EdgeInsets.only(left: 10.0, top: 30.0, bottom: 5.0),
                  ),
                  Container(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onChanged: (value) {
                              filterSearchResults(value);
                            },
                            controller: editingController,
                            decoration: InputDecoration(
                                labelText: "식물 종을 선택해주세요.",
                                hintText: "Search",
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(25.0)))),
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text('${items[index]}'),
                                onTap: () {
                                  editingController.text = items[index];
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Container(
                  //   child: Theme(
                  //     data: Theme.of(context)
                  //         .copyWith(primaryColor: primaryColor),
                  //     child: TextField(
                  //       onChanged: (value) {
                  //         filterSearchResults(value);
                  //       },
                  //       controller: editingController,
                  //       decoration: InputDecoration(
                  //           labelText: "Search",
                  //           hintText: "식물 종을 선택해주세요.",
                  //           prefixIcon: Icon(Icons.search),
                  //           border: OutlineInputBorder(
                  //               borderRadius:
                  //                   BorderRadius.all(Radius.circular(25.0)))),
                  //     ),
                  //   ),
                  //   margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  // ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),

              // Button
              Container(
                child: TextButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    '등록하기',
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
                ),
                margin: EdgeInsets.only(top: 50.0, bottom: 50.0),
              ),
            ],
          ),
          padding: EdgeInsets.only(left: 15.0, right: 15.0),
        ),

        // Loading
        Positioned(
          child: isLoading
              ? Container(
                  child: Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
                  ),
                  color: Colors.white.withOpacity(0.8),
                )
              : Container(),
        ),
      ],
    );
  }
}

Future<void> showNotification() async {
  var android = AndroidNotificationDetails(
      'channelId', 'channelName', 'channelDescription',
      importance: Importance.max, priority: Priority.max);
  var iOS = IOSNotificationDetails();
  var platform = NotificationDetails(android: android, iOS: iOS);

  await FlutterLocalNotificationsPlugin().show(0, 'title', 'body', platform);
}
