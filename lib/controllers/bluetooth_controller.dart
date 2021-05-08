import 'package:flutter_blue/flutter_blue.dart';

BluetoothDevice gConnectedDevice;
BluetoothCharacteristic gConnectedCharacteristic;

// class BluetoothController {
//   static connectB612(ScanResult r) async {
//     Get.back();
//     Future.delayed(Duration(seconds: 1)).then((value) async {
//       Get.dialog(
//         AlertDialog(
//           contentPadding: EdgeInsets.all(Get.size.width / 3),
//           content: AspectRatio(
//             aspectRatio: 1,
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
//             ),
//           ),
//           backgroundColor: Colors.transparent,
//         ),
//         barrierDismissible: true,
//       );
//       gConnectedDevice = r.device;
//       gConnectedDevice?.state.listen((BluetoothDeviceState event) {
//         if (event == BluetoothDeviceState.disconnected) {
//           Get.find<AppData>().isConnected = false;
//           Get.find<AppData>().isMusicPlaying = false;
//           Get.find<AppData>().isMuted = false;
//           SoundController.stop();
//         }
//       });
//
//       await r.device.connect();
//       await r.device.discoverServices();
//       r.device.services.listen((List<BluetoothService> event) {
//         if (Get.find<AppData>().isConnected) {
//           return;
//         }
//         event.forEach((BluetoothService element) async {
//           print('${element.uuid.toString().toUpperCase().substring(4, 8)}');
//           if ((element.uuid.toString().toUpperCase().substring(4, 8)) ==
//               'FFE0') {
//             Get.find<AppData>().isConnected = true;
//             BluetoothCharacteristic c = element.characteristics.first;
//             await c.setNotifyValue(true);
//             await c.read();
//             gConnectedCharacteristic = c;
//             Timer.periodic(Duration(milliseconds: 50), _timerCallback);
//             c.value.listen(_bluetoothReceiveCallback);
//           }
//         });
//       });
//       Get.back();
//     });
//   }
// }
