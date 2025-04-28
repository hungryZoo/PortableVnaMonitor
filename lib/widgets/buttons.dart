// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:developer' as dev;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scidart/numdart.dart';
import 'package:pvm_col/data.dart';
import 'package:pvm_col/functions.dart';
import 'package:pvm_col/messages.dart';
import 'package:path_provider/path_provider.dart';

import 'dialogs.dart';

// ---------bluetoothConnectButton--------------------------------------------

class bluetoothConnectButton extends StatefulWidget {
  const bluetoothConnectButton({super.key});

  @override
  bluetoothConnectButtonState createState() => bluetoothConnectButtonState();
}

class bluetoothConnectButtonState extends State<bluetoothConnectButton> {
  int idx = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        bluetoothConnectButtonStringIndex = 0;
        connectedDeviceName = "None";
        deviceEqual = "Device : ";
      });
    });
  }

  showBleDeviceList() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const bleDeviceDialog();
      },
    ).then(
      (value) {
        // dialog가 종료되면 연결된 기기 이름과 connected로 업데이트
        if (mounted) {
          dev.log("mounted!!");
          dev.log("connectDeviceName : $connectedDeviceName");
          setState(() {});
        } else {
          dev.log("then not mounted");
        }
      },
    );
  }

  // 버튼 클릭시 창이 나오고,
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(baseSize * 1),
            child: TextButton(
              onPressed: () async {
                setState(() {});
                if (bluetoothConnectButtonStringIndex == 0) {
                  dev.log("dialog on");
                  showBleDeviceList();
                  setState(() {});
                } else {
                  bleDeviceDisconnect();
                }
              },
              style: baseButton(),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  buttonText[bluetoothConnectButtonStringIndex],
                  style: TextStyle(fontSize: baseSize * 5, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Text(
                deviceEqual,
                style: connectButtonStyle(),
              ),
              Text(
                connectedDeviceName,
                style: connectButtonStyle(),
              )
            ],
          ),
        ),
      ],
    );
  }

  connectButtonStyle({double size = 2.4}) {
    return TextStyle(
      fontSize: baseSize * size,
    );
  }

  bleDeviceDisconnect() {
    // 블루투스 기기와의 연결 끊기
    if (isConnected) {
      isConnected = false;
      selectedDevice.device.disconnect();
      negativeToast("disconnect");
      setState(() {
        bluetoothConnectButtonStringIndex = 0;
        connectedDeviceName = "None";
      });
    }
  }

  connectButtonSet() {
    if (mounted) {
      setState(() {});
    } else {
      dev.log("not mounted");
    }
  }
}

// ---------settingParameterButton------------------------------------------------

// class settingParameterButton extends StatefulWidget {
//   const settingParameterButton({super.key});

//   @override
//   settingParameterButtonState createState() => settingParameterButtonState();
// }

// class settingParameterButtonState extends State<settingParameterButton> {
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     freqStartStr = 'Freq Start';
//     freqEndStr = 'Freq end';
//     numSweepPointStr = 'Num Sweep Point';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       child: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: EdgeInsets.only(top: baseSize * 1),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       freqStartStr,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: baseSize * 2.3),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 1,
//                     child: Padding(
//                       padding: EdgeInsets.only(right: baseSize * 1),
//                       child: TextField(
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                         ),
//                         textAlign: TextAlign.center,
//                         keyboardType: TextInputType.number,
//                         enabled: isToggle,
//                         controller: freqStartNumController,
//                         onSubmitted: (value) {
//                           setState(() {
//                             freqStart = int.parse(value);
//                           });
//                         },
//                         strutStyle: settingParameterStrutStyle(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: EdgeInsets.only(top: baseSize * 1),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       freqEndStr,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: baseSize * 2.3),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 1,
//                     child: Padding(
//                       padding: EdgeInsets.only(right: baseSize * 1),
//                       child: TextField(
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                         ),
//                         textAlign: TextAlign.center,
//                         enabled: isToggle,
//                         controller: freqEndNumController,
//                         strutStyle: settingParameterStrutStyle(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: EdgeInsets.only(top: baseSize * 1),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       numSweepPointStr,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: baseSize * 2),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 1,
//                     child: Padding(
//                       padding: EdgeInsets.only(right: baseSize * 1),
//                       child: TextField(
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                         ),
//                         textAlign: TextAlign.center,
//                         enabled: false,
//                         controller: numSweepPointNumController,
//                         strutStyle: settingParameterStrutStyle(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   set() {
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   settingParameterText(String title) {
//     return FittedBox(
//       fit: BoxFit.fitWidth,
//       child: Text(
//         textAlign: TextAlign.center,
//         title,
//         style: settingParameterTextStyle(),
//       ),
//     );
//   }

//   settingParameterStrutStyle() {
//     return const StrutStyle();
//   }

//   settingParameterTextStyle() {
//     return TextStyle(
//       fontSize: baseSize * 1.4,
//     );
//   }
// }

// ----------toggleButton--------------------------------------------------

// class toggleButton extends StatefulWidget {
//   final void Function() changeSet;

//   const toggleButton({super.key, required this.changeSet});

//   @override
//   toggleButtonState createState() => toggleButtonState();
// }

// class toggleButtonState extends State<toggleButton> {
//   @override
//   Widget build(BuildContext context) {
//     return Switch(
//       value: isToggle,
//       onChanged: (value) {
//         isToggle = value;
//         dev.log(isToggle.toString());
//         widget.changeSet();
//       },
//     );
//   }
// }

// ---------startButton---------------------------------------------------

class startButton extends StatefulWidget {
  const startButton({super.key});

  @override
  startButtonState createState() => startButtonState();
}

class startButtonState extends State<startButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(baseSize * 1),
            child: TextButton(
              onPressed: () {
                setState(() {});
                dev.log("press start button");
                if (isConnected && mounted) {
                  // toggle이 활성화 되어 있어야 가능
                  !isGraphing ? startGraph() : stopGraph();
                }
              },
              style: ButtonStyle(
                alignment: Alignment.topCenter,
                backgroundColor:
                    const WidgetStatePropertyAll(Colors.deepPurple),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  !isGraphing ? startStr : stopStr,
                  style: TextStyle(
                    fontSize: baseSize * 4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  startGraph() async {
    dev.log("start graph dd");
    fileDataBuffer = '';
    setState(() {
      isGraphing = true;
    });

    mainGraphX = 0;
    mainGraphData = initMainGraphData(150);

    // phaseGraphData = initGraphData(11);
    // gainGraphData = initGraphData(11);

    await heartRateMeasurementCharcteristic.setNotifyValue(true).then((value) {
      xValue = 0;
      dev.log("set notify value");
    });

    stream =
        heartRateMeasurementCharcteristic.onValueReceived.listen((dataList) {
      dev.log("start!!!");
      int len = dataList.length;
      int dataLen = (len - 1) ~/ 4;

      /*
      1. phase, gain raw data
      2. phase, gain
      3. zRear, zImg
      */
      List<int> phaseOriginData = [];
      List<int> gainOriginData = [];

      List<double> phaseProcessedData = [];
      List<double> gainProcessedData = [];

      List<double> zRealData = [];
      List<double> zImgData = [];

      double phaseValue, gainValue;

      // received data from BLE device.
      dev.log("received data");
      for (int i = 1; i < len; i += 4) {
        phaseOriginData.add(dataList[i] + dataList[i + 1] * 256);
        gainOriginData.add(dataList[i + 2] + dataList[i + 3] * 256);
      }

      //  original data processing
      dev.log("origin data");
      for (int i = 0; i < dataLen; i++) {
        phaseValue = phaseOriginData[i].toDouble();
        gainValue = gainOriginData[i].toDouble();

        phaseValue *= (1.8 / 16384);
        phaseProcessedData.add(phaseValue / 0.01);

        gainValue *= (1.8 / 16384);
        gainValue = -30 + (gainValue / 0.03);
        gainProcessedData.add(pow(10, (gainValue / 20)).toDouble());
      }

      int rTx = 5;
      // z data processing
      dev.log("z data");
      for (int i = 0; i < dataLen; i++) {
        double gainTx = gainProcessedData[i];
        double phaseTx = phaseProcessedData[i];

        zRealData.add((gainTx * cos(pi - (phaseTx * pi / 180)) - 1) * rTx);
        zImgData.add((gainTx * sin(pi - (phaseTx * pi / 180))) * rTx);
      }

      // // dev.log("txrxZreal start");
      // Array txrxZReal = Array(zRealData);
      // // dev.log("txrxZreal end");

      // // dev.log("txrxZImag start");
      // Array txrxZImag = Array(zImgData);
      // // dev.log("txrxZImag end");

      // // dev.log("zReal start");
      // Array zReal = txrxZReal - TX.txZRealMean;
      // // Array zImag = txrxZImag - TX.txZImagMean;
      // // dev.log("zReal end");

      // // dev.log("zrealFilt start");
      // Array zrealFilt = TX.convFilter(zReal);
      // // dev.log("zrealFilt end");

      // // dev.log("zrealInterp start");
      // Array zrealInterp = TX.matResample(zrealFilt);
      // // dev.log("zrealInterp end");

      // // dev.log("resFreq start");
      // double resFreq = TX.getPeakFrequencyFromResample(zrealInterp);
      // // dev.log("resFreq end");

      // draw graph using origin data
      // for (int i = 0; i < dataLen; i++) {
      //   phaseGraphData.add(GraphData(dataCnt, phaseOriginData[i]));
      //   gainGraphData.add(GraphData(dataCnt, gainOriginData[i]));
      //   phaseGraphData.removeAt(0);
      //   gainGraphData.removeAt(0);
      //   phaseGraphController.updateDataSource(
      //       addedDataIndex: phaseGraphData.length - 1, removedDataIndex: 0);
      //   gainGraphController.updateDataSource(
      //       addedDataIndex: gainGraphData.length - 1, removedDataIndex: 0);
      //   dataCnt++;
      // }

      if (showZCheckBoxState == true) {
        // draw graph usig z data
        for (int i = 0; i < dataLen; i++) {
          phaseGraphData.add(GraphData(xValue, zRealData[i]));
          gainGraphData.add(GraphData(xValue, zImgData[i]));

          phaseGraphData.removeAt(0);
          gainGraphData.removeAt(0);

          phaseGraphController.updateDataSource(
              addedDataIndex: phaseGraphData.length - 1, removedDataIndex: 0);
          gainGraphController.updateDataSource(
              addedDataIndex: gainGraphData.length - 1, removedDataIndex: 0);

          xValue++;
        }
      } else {
        // draw graph using processed data
        for (int i = 0; i < dataLen; i++) {
          phaseGraphData.add(GraphData(xValue, phaseProcessedData[i]));
          gainGraphData.add(GraphData(xValue, gainProcessedData[i]));

          phaseGraphData.removeAt(0);
          gainGraphData.removeAt(0);

          phaseGraphController.updateDataSource(
              addedDataIndex: phaseGraphData.length - 1, removedDataIndex: 0);
          gainGraphController.updateDataSource(
              addedDataIndex: gainGraphData.length - 1, removedDataIndex: 0);

          xValue++;
        }
      }
      // ----------------main graph------------------------
      if (isFileSelected) {
        dev.log("update main graph");
        // int mainGraphY = Random().nextInt(30);
        // mainGraphY = resFreq;

        mainGraphData[mainGraphX] = MainGraphData(mainGraphX, 10);
        mainGraphX = (mainGraphX + 1) % 150;
        mainGraphData[mainGraphX] = MainGraphData(mainGraphX, null);
        mainGraphController!.updateDataSource();
        setState(() {});
        dev.log("x value : $mainGraphX");
        dev.log("updated main graph");
      }
      setState(() {});

      fileDataBuffer += DateTime.now().toString();
      for (int i = 0; i < dataLen; i++) {
        fileDataBuffer +=
            ' ${phaseOriginData[i].toString()} ${gainOriginData[i].toString()}';
      }
      fileDataBuffer += '\n';
      xValue = 0;
    });
  }

  stopGraph() async {
    stream.cancel();
    heartRateMeasurementCharcteristic.setNotifyValue(false);
    setState(() {
      isGraphing = false;
    });

    IOSink sink = await makeFile(); // 파일과의 연결고리
    dev.log("sink state : ${sink.done.toString()}");
    sink.write('$freqStart $freqEnd $numSweepPoint\n');
    sink.write(fileDataBuffer);
    dev.log("fileDataBuffer length : ${fileDataBuffer.length}");
    sink.close();

    getExternalStorageDirectoryPath().then((directoryPath) {
      getFilesFromDirectory(tmpDirPath).then((Files) {
        setState(() {
          filePathList = ["None : record only"]; // 맨 처음은 무조건 None이 들어가야 하므로
          filePathList.addAll(Files);
          selectedFilePath = filePathList.first;
        });
      });
    });
    isFileSelected = false;
    positiveToast("file save to $filePath");
  }

  Future<IOSink> makeFile() async {
    await checkPermission();

    tmpDirectory = Directory(tmpDirPath);

    if (!tmpDirectory.existsSync()) {
      await tmpDirectory.create();
    }

    filePath = '$tmpDirPath/${getFileName()}';
    file = File(filePath);
    dev.log('created file path : $filePath');

    return file.openWrite(mode: FileMode.writeOnly);
  }
}

ButtonStyle baseButton() {
  return ButtonStyle(
    backgroundColor: const WidgetStatePropertyAll(Colors.deepPurple),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

Future<List<String>> getFilesFromDirectory(String directoryPath) async {
  try {
    final directory = Directory(directoryPath);
    final files = await directory.list().toList();
    return files.whereType<File>().map((file) => file.path).toList();
  } catch (e) {
    dev.log('Error fetching files: $e');
    return [];
  }
}

Future<String> getExternalStorageDirectoryPath() async {
  final directory = await getExternalStorageDirectory();
  return directory!.path;
}
