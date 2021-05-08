import 'package:http/http.dart' as http;

class HttpController {
  static Future<void> sendMoistureToServer(
      {required String deviceId, required double moisture}) async {
    var url = 'https://api.dearplants.co.kr/chatfuel/moisture?moisture=' +
        moisture.toStringAsFixed(1) +
        '&device_id=' +
        deviceId;

    print('url : $url');

    http.Response response = await http.post(
      Uri.parse(url),
    );
  }
}
