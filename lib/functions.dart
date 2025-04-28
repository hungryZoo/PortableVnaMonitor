import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data.dart';

import 'messages.dart';

import 'dart:developer' as dev;

checkPermission() async {
  /// request bluetooth-related permission
  PermissionStatus bluetoothStatus = await Permission.bluetooth.request();
  PermissionStatus bluetoothAdvertiseStatus =
      await Permission.bluetoothAdvertise.request();
  PermissionStatus bluetoothScanStatus =
      await Permission.bluetoothScan.request();
  PermissionStatus bluetoothConnectStatus =
      await Permission.bluetoothConnect.request();
  // PermissionStatus manageExternalStatus =
  //     await Permission.manageExternalStorage.request();

  /// log each permission status
  dev.log(bluetoothStatus.toString());
  dev.log(bluetoothConnectStatus.toString());
  dev.log(bluetoothAdvertiseStatus.toString());
  dev.log(bluetoothScanStatus.toString());
  // dev.log(manageExternalStatus.toString());

  checkBluetoothOn();
}

// check Bluetooth On
bool checkBluetoothOn() {
  bool result = true;
  FlutterBluePlus.adapterState.listen((status) {
    // H : BluetoothState -> BluetoothAdapterState
    if (status == BluetoothAdapterState.off) {
      negativeToast("Please turn on the bluetooth");
      result = false;
    }
  });
  return result;
}

String getFileName() {
  final now = DateTime.now();

  final year = now.year.toString().substring(2);
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');

  return '$year$month${day}_$hour$minute$second.txt';
}

String getTrendFileName() {
  final now = DateTime.now();

  final year = now.year.toString().substring(2);
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');

  return '$year$month${day}_$hour$minute${second}_trend.txt';
}

List<GraphData> initGraphDataUsingVal(int val) {
  double interval = (freqEnd - freqStart) / (val - 1);
  double value = freqStart.toDouble();
  List<GraphData> returnData = [];
  dev.log("dataLen : $val");
  for (int i = 0; i < val; i++) {
    returnData.add(GraphData((value), 0));
    value += interval;
  }
  return returnData;
}

// 현재의 numSweepPoint를 기준으로 데이터를 초기화 한다.
void initGraphData() {
  double interval = (freqEnd - freqStart) / (numSweepPoint - 1);
  double value = freqStart.toDouble();

  phaseGraphData.clear();
  gainGraphData.clear();
  for (int i = 0; i < numSweepPoint; i++) {
    phaseGraphData.add(GraphData((value), 0));
    gainGraphData.add(GraphData((value), 0));
    value += interval;
  }
}

List<MainGraphData> initMainGraphData(int dataCnt) {
  return <MainGraphData>[
    for (double i = 0; i < dataCnt; i += 1) MainGraphData(i.toInt(), null)
  ];
}
