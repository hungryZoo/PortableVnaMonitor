// ignore_for_file: camel_case_types
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pvm_col/data.dart';
import 'package:pvm_col/messages.dart';
import 'package:pvm_col/functions.dart';
import 'buttons.dart';
import 'base.dart';

class bleDeviceDialog extends StatefulWidget {
  const bleDeviceDialog({super.key});

  @override
  bleDeviceDialogState createState() => bleDeviceDialogState();
}

class bleDeviceDialogState extends State<bleDeviceDialog> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dev.log("show");
      await startScan();
    });
  }

  onTab() async {
    positiveToast("Connecting...");
    await bleDeviceConnect();
    FlutterBluePlus.stopScan();
  }

  Future<bool> bleDeviceConnect() async {
    Future<bool>? returnValue;
    await selectedDevice.device
        .connect(autoConnect: false)
        .timeout(const Duration(milliseconds: 5000), onTimeout: () {
      negativeToast('Timeout error');
      returnValue = Future.value(false);
    }).then((data) {
      if (returnValue == null) {
        //button text를 connected로 변경
        bluetoothConnectButtonStringIndex = 1;
        dev.log("setting success");
        bluetoothConnectButtonState().connectButtonSet();

        if (selectedDevice.device.platformName.isNotEmpty) {
          connectedDeviceName = selectedDevice.device.platformName;
        } else {
          connectedDeviceName = selectedDevice.advertisementData.advName;
        }

        dev.log("connectDeviceName : $connectedDeviceName");
        isConnected = true;

        returnValue = Future.value(false);
      } else {
        negativeToast("error in connect");
      }
    }).catchError((error) {
      negativeToast(error);
    });

    // heartRateMeuserement Service 찾기
    selectedDevice.device.discoverServices().then((serviceList) {
      for (var service in serviceList) {
        if (service.uuid.toString() == '180d') {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == '2a37') {
              heartRateMeasurementCharcteristic = characteristic;
              dev.log(
                  "set heartRateMeasurementCharcteristic : $heartRateMeasurementCharcteristic");
            }
          }
        }
      }
    });

    positiveToast("Connection Succesful");

    Navigator.of(context).pop();
    return returnValue ?? Future.value(false);
  }

  startScan() async {
    // 권한 or 블루투스 확인
    checkBluetoothOn();
    checkPermission();

    FlutterBluePlus.startScan(
      timeout: const Duration(
        seconds: 100,
      ),
    );

    try {
      FlutterBluePlus.scanResults.listen(
        (scanResults) {
          for (ScanResult element in scanResults) {
            // rssi, 기존에 추가되었는지, 이름이 있는지 확인
            if (element.rssi > -70 &&
                !bleIdList.contains(element.hashCode) &&
                (element.device.platformName.isNotEmpty ||
                    element.advertisementData.advName.isNotEmpty)) {
              bleIdList.add(element.hashCode);
              bluetoothScanResult.add(element);
              bluetoothConnectButtonState().connectButtonSet();

              if (mounted) {
                setState(() {});
              }
            }
          }
        },
      );
    } catch (error) {
      dev.log("error : ${error.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        height: double.maxFinite,
        width: baseSize * 33,
        child: ListView.separated(
          itemCount: bluetoothScanResult.length,
          itemBuilder: (BuildContext context, int index) {
            return listItem(bluetoothScanResult[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("닫기"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    bluetoothScanResult.clear();
    bleIdList.clear();
    FlutterBluePlus.stopScan();
  }

  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () {
        selectedDevice = r;
        onTab();
      },
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: deviceSignal(r),
    );
  }
}
