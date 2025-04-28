import 'package:flutter/material.dart';
import 'package:pvm_col/data.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

Widget margin(double i) {
  return SizedBox(
    child: SizedBox(
      height: size.height * 0.01 * i,
      width: size.width * 0.01 * i,
    ),
  );
}

Widget deviceSignal(ScanResult r) {
  return Text(r.rssi.toString());
}

Widget deviceMacAddress(ScanResult r) {
  return Text(r.device.remoteId.str);
}

Widget deviceName(ScanResult r) {
  String name = '';

  if (r.device.platformName.isNotEmpty) {
    name = r.device.platformName;
  } else {
    name = r.advertisementData.advName;
  }
  return Text(name);

  // else if (r.advertisementData.advName.isNotEmpty) {
  //   name = r.advertisementData.advName;
  // } else {  // 이럴 경우는 없긴 하다
  //   name = 'N/A';
  // }
}

Widget leading(ScanResult r) {
  return const CircleAvatar(
    backgroundColor: Colors.cyan,
    child: Icon(
      Icons.bluetooth,
      color: Colors.white,
    ),
  );
}

Widget fileLeading(String fileName) {
  return const CircleAvatar(
    backgroundColor: Colors.cyan,
    child: Icon(
      Icons.file_open,
      color: Colors.white,
    ),
  );
}
