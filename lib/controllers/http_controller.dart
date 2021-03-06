import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

List<String> plantNameAll;

class HttpController {
  static Future<void> sendMoistureToServer(
      {@required String moisture,
      @required String email,
      @required String nick}) async {
    var url = 'https://api.dearplants.co.kr/plant/dearplant/moisture';

    Map data = {'moisture': moisture, 'email': email, 'nick': nick};

    print('url : $url');

    http.Response response = await http.post(
      Uri.parse(url),
      body: data,
    );
  }

  static Future<void> sendTouchEvent(
      {@required String email, @required String nick}) async {
    var url = 'https://api.dearplants.co.kr/plant/dearplant/touch';

    print("touch event email: " + email);
    print("touch event nick: " + nick);

    Map data = {'email': email, 'nick': nick};

    print('url : $url');

    http.Response response = await http.post(
      Uri.parse(url),
      body: data,
    );
  }

  static Future<void> registerPlant(
      {@required String nick,
      @required String typename,
      @required String email}) async {
    var url = 'https://api.dearplants.co.kr/plant/dearplant';

    Map data = {'nick': nick, 'typename': typename, 'email': email};

    print('url : $url');

    http.Response response = await http.post(
      Uri.parse(url),
      body: data,
    );
  }

  static Future<void> signUp(
      {@required String email, @required String fcmId}) async {
    var url = 'https://api.dearplants.co.kr/account/dearplant/sign-up';

    Map data = {'email': email, 'fcm_id': fcmId};
    //encode Map to JSON
    //var body = json.encode(data);

    http.Response response = await http.post(Uri.parse(url), body: data);
  }

  static Future<void> signIn({@required String email}) async {
    var url = 'https://api.dearplants.co.kr/account/dearplant/sign-in';

    Map data = {'email': email};
    //encode Map to JSON
    //var body = json.encode(data);

    http.Response response = await http.post(Uri.parse(url), body: data);
  }

  static Future<void> getPlantNameAll() async {
    var url = 'https://api.dearplants.co.kr/plant/dearplantsearch';

    print('url : $url');

    http.Response response = await http.get(
      Uri.parse(url),
    );
    if (response.statusCode == 200) {
      plantNameAll = json.decode(response.body)['data'].cast<String>();
    }
  }

  //???????????? //?????? ID
  static Future<String> sendChat(
      {@required String nick,
      @required String message,
      @required String email,
      @required String groupChatId,
      @required String id,
      @required String peerId,
      @required int type}) async {
    var url = 'https://api.dearplants.co.kr/chat/dearplant?nick=' +
        nick +
        '&message=' +
        message +
        '&email=' +
        email;

    print('url : $url');

    http.Response response = await http.post(
      Uri.parse(url),
    );

    if (response.statusCode == 200) {
      var decoded = json.decode(response.body)['data'];
      if (decoded.length == 1) {
        FirebaseFirestore.instance
            .collection('messages')
            .doc(groupChatId)
            .collection(groupChatId)
            .add({
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'idFrom': peerId,
          'idTo': id,
          'content': decoded[0]['messageText'],
          'type': type
        });
      } else {
        FirebaseFirestore.instance
            .collection('messages')
            .doc(groupChatId)
            .collection(groupChatId)
            .add({
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'idFrom': peerId,
          'idTo': id,
          'content': decoded[0]['messageText'],
          'type': type
        });
        if (decoded[0]['messageType'] == 'PHOTO') {
          FirebaseFirestore.instance
              .collection('messages')
              .doc(groupChatId)
              .collection(groupChatId)
              .add({
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'idFrom': peerId,
            'idTo': id,
            'content': decoded[1]['messageText'],
            'type': 0
          });
        } else {
          FirebaseFirestore.instance
              .collection('messages')
              .doc(groupChatId)
              .collection(groupChatId)
              .add({
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'idFrom': peerId,
            'idTo': id,
            'content': decoded[1]['messageText'],
            'type': 1
          });
        }
      }
      print('chat message : $decoded');
      // return decoded;

      // FirebaseFirestore.instance
      //     .collection('messages')
      //     .doc(groupChatId)
      //     .collection(groupChatId)
      //     .add({
      //   'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      //   'idFrom': peerId,
      //   'idTo': id,
      //   'content': content,
      //   'type': type
      // });
    }
    //return '';
  }
}
