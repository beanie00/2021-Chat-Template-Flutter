import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HttpController {
  static Future<void> sendMoistureToServer(
      {@required String deviceId, @required double moisture}) async {
    var url = 'https://api.dearplants.co.kr/chatfuel/moisture?moisture=' +
        moisture.toStringAsFixed(1) +
        '&device_id=' +
        deviceId;

    print('url : $url');

    http.Response response = await http.post(
      Uri.parse(url),
    );
  }

  //기기번호 //식물 ID
  static Future<String> sendChat(
      {@required String moisture,
      @required String message,
      @required String user_id,
      @required String groupChatId,
      @required String id,
      @required String peerId,
      @required int type}) async {
    var url = 'http://6cac4214b76d.ngrok.io/chat/dearplant?moisture=' +
        moisture +
        '&message=' +
        message +
        '&user_id=' +
        user_id;

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
            'type': 1
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
            'type': 0
          });
        }
      }
      print('chat message : $decoded');
      return decoded;

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
    return '';
  }
}
