/// checkbox에 따라서 그래프의 세팅이 변해야 하므로 twoPageScreen.dart를 함께 포함시켰다.
library;

import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pvm_col/data.dart';
import 'package:pvm_col/functions.dart';
import 'package:pvm_col/messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_size_text/auto_size_text.dart';

// import 'package:pvm_col/calculate.dart';
import 'package:pvm_col/test3.dart';
import 'package:pvm_col/widgets/base.dart';
// import 'package:pvm_col/widgets/buttons.dart';
import 'package:pvm_col/widgets/dialogs.dart';
import 'package:scidart/numdart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:iirjdart/butterworth.dart';

extension ListDoubleMinusOps on List<double> {
  List<double> minus(List<double> other) {
    if (length != other.length) {
      throw Exception('두 리스트의 길이가 같아야 합니다.');
    }
    return List.generate(length, (i) => this[i] - other[i]);
  }
}

extension ListDoublePlusOps on List<double> {
  List<double> plus(List<double> other) {
    if (length != other.length) {
      throw Exception('두 리스트의 길이가 같아야 합니다.');
    }
    return List.generate(length, (i) => this[i] + other[i]);
  }
}

Map<String, double> computeValueIsolate(List<dynamic> data) {
  // data[0] -> sig (List<double>)
  // data[1] -> coef (List<double>)
  List<double> sig = data[0] as List<double>;
  List<double> coef = data[1] as List<double>;

  // MEASURE TIME
  Stopwatch stopwatch = Stopwatch()..start();

  // INITIAL
  double Fs = 40;
  double L = data[0].length.toDouble() / Fs;

  // FILTER
  List<double> sigfDC = myFilter(sig, 2, Fs, 0.2);
  List<double> sigfHR = myFilter(sig.minus(sigfDC), 2, Fs, 1.8).plus(sigfDC);
  List<double> sigfBP = myFilter(sig.minus(sigfDC), 2, Fs, 4.5).plus(sigfDC);

  // print(sigfDC);
  // print("");
  // print(sigfHR);
  // print("");
  // print(sigfBP);

  // DETECT PEAKS
  List<int> peakIdx = myFindPeaks(sigfHR);
  List<int> peakDownIdx = myFindPeaksVelly(sigfHR);

  peakIdx.removeWhere((element) => element >= (L - 0.25) * Fs);
  peakDownIdx.removeWhere((element) => element >= (L - 0.25) * Fs);

  // print("");
  // print(peakIdx);
  // print("");
  // print(peakDownIdx);

  // CALCULATE INFORMATION
  double HR = 0;
  double SBP = 0;
  double DBP = 0;

  // coef[6] -> coefOffSet
  if (peakIdx.length >= 2) {
    HR = (60 / (myMean(myDiff(peakIdx)) / Fs));
    SBP = sigfBP[peakIdx[0]];
    SBP = coef[0] * pow(SBP, 0) +
        coef[1] * pow(SBP, 1) +
        coef[2] * pow(SBP, 2) +
        coef[3] * pow(SBP, 3) +
        coef[4] * pow(SBP, 4) +
        coef[5] * pow(SBP, 5) +
        coef[6];
    DBP = sigfBP[peakDownIdx[0]];
    DBP = coef[0] * pow(DBP, 0) +
        coef[1] * pow(DBP, 1) +
        coef[2] * pow(DBP, 2) +
        coef[3] * pow(DBP, 3) +
        coef[4] * pow(DBP, 4) +
        coef[5] * pow(DBP, 5) +
        coef[6];
  }
  // print(HR);
  // print(SBP);
  // print(DBP);

  // MEASURE TIME
  stopwatch.stop(); // 스톱워치 정지
  print('수행 시간: ${stopwatch.elapsedMilliseconds} ms');

  return {'HR': HR, 'SBP': SBP, 'DBP': DBP};
}

List<double> myFilter(List<double> sig, int n, double Fs, double cutoff) {
  Butterworth but = new Butterworth();
  but.lowPass(n, Fs, cutoff);

  List<double> tmp = List.filled(sig.length, 0);
  double offset = 0;
  offset = sig[0];
  but.reset();
  for (int i = 0; i < tmp.length; i++) {
    tmp[i] = but.filter(sig[i] - offset) + offset;
  }

  tmp = tmp.reversed.toList();

  offset = tmp[0];
  but.reset();
  for (int i = 0; i < tmp.length; i++) {
    tmp[i] = but.filter(tmp[i] - offset) + offset;
  }

  tmp = tmp.reversed.toList();
  return tmp;
}

List<int> myFindPeaks(List<double> sig) {
  int distance = 15;
  List<int> peakIdx = [-distance];

  for (int i = 1; i < sig.length - 1; i++) {
    if ((sig[i - 1] < sig[i]) && (sig[i] >= sig[i + 1])) {
      if (peakIdx.last + distance <= i) {
        peakIdx.add(i);
      }
    }
  }
  peakIdx.removeAt(0);
  return peakIdx;
}

List<int> myFindPeaksVelly(List<double> sig) {
  int distance = 15;
  List<int> peakIdx = [-distance];

  for (int i = 1; i < sig.length - 1; i++) {
    if ((sig[i - 1] > sig[i]) && (sig[i] <= sig[i + 1])) {
      if (peakIdx.last + distance <= i) {
        peakIdx.add(i);
      }
    }
  }
  peakIdx.removeAt(0);
  return peakIdx;
}

List<int> myDiff(List<int> idx) {
  if (idx.length <= 1) {
    return List<int>.empty();
  }

  return List<int>.generate(idx.length - 1, (i) => idx[i + 1] - idx[i]);
}

double myMean(List<int> list) {
  if (list.isEmpty) {
    throw Exception("리스트가 비어 있습니다.");
  }
  return list.reduce((a, b) => a + b) / list.length;
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  ControlScreenState createState() => ControlScreenState();
}

class ControlScreenState extends State<ControlScreen> {
  double freqStartLocal = freqStart;
  double freqEndLocal = freqEnd;
  int numSweepPointLocal = numSweepPoint;
  int updateIntervalLocal = graphUpdateInterval;
  double rTxLocal = rTx;
  double coef0Local = coef0;
  double coef1Local = coef1;
  double coef2Local = coef2;
  double coef3Local = coef3;
  double coef4Local = coef4;
  double coef5Local = coef5;
  double coefOffSetLocal = coefOffSet;
  double pressureStartLocal = pressureStart;
  double pressureEndLocal = pressureEnd;

  int hrValue = 1;
  int sbpValue = 1;
  int dbpValue = 1;
  double yAxisMin = freqStart;
  double yAxisMax = freqEnd;
  List<double> calcBuffer = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    settingFileList();
    isFileSelected = false;
    freqStartNumController =
        TextEditingController(text: freqStartLocal.toString());
    freqEndNumController = TextEditingController(text: freqEndLocal.toString());
    numSweepPointNumController =
        TextEditingController(text: numSweepPointLocal.toString());
    updateIntervalController =
        TextEditingController(text: updateIntervalLocal.toString());
    rTxController = TextEditingController(text: rTxLocal.toString());
    coef0NumController = TextEditingController(text: coef0.toString());
    coef1NumController = TextEditingController(text: coef1.toString());
    coef2NumController = TextEditingController(text: coef2.toString());
    coef3NumController = TextEditingController(text: coef3.toString());
    coef4NumController = TextEditingController(text: coef4.toString());
    coef5NumController = TextEditingController(text: coef5.toString());
    coefOffSetNumController =
        TextEditingController(text: coefOffSet.toString());
    pressureStartNumController =
        TextEditingController(text: pressureStart.toString());
    pressureEndNumController =
        TextEditingController(text: pressureEnd.toString());

    freqStartStr = 'Freq Start';
    freqEndStr = 'Freq End';
    numSweepPointStr = 'Num Sweep Point';
    updateIntervalStr = 'Update Interval';
    deviceEqual = "Device : ";
    connectedDeviceName = "None";
    globalCoef[0] = coef0Local;
    globalCoef[1] = coef1Local;
    globalCoef[2] = coef2Local;
    globalCoef[3] = coef3Local;
    globalCoef[4] = coef4Local;
    globalCoef[5] = coef5Local;
    globalCoef[6] = coefOffSetLocal;
    // gainGraphData = initGraphData();
    // phaseGraphData = initGraphData();
    mainGraphData = initMainGraphData(150);

    _load();

    updateIntervalController.addListener(() {
      if (updateIntervalController.text != "") {
        setState(() {
          graphUpdateInterval = int.parse(updateIntervalController.text) - 1;
          dev.log("update interval : $graphUpdateInterval");
        });
      }
    });
  }

  Future<void> _save() async {
    freqStartLocal = double.parse(freqStartNumController.text);
    freqEndLocal = double.parse(freqEndNumController.text);
    rTxLocal = double.parse(rTxController.text);
    coef0Local = double.parse(coef0NumController.text);
    coef1Local = double.parse(coef1NumController.text);
    coef2Local = double.parse(coef2NumController.text);
    coef3Local = double.parse(coef3NumController.text);
    coef4Local = double.parse(coef4NumController.text);
    coef5Local = double.parse(coef5NumController.text);
    coefOffSetLocal = double.parse(coefOffSetNumController.text);
    pressureStartLocal = double.parse(pressureStartNumController.text);
    pressureEndLocal = double.parse(pressureEndNumController.text);
    freqStart = freqStartLocal;
    freqEnd = freqEndLocal;
    rTx = rTxLocal;
    coef0 = coef0Local;
    coef1 = coef1Local;
    coef2 = coef2Local;
    coef3 = coef3Local;
    coef4 = coef4Local;
    coef5 = coef5Local;
    coefOffSet = coefOffSetLocal;
    pressureStart = pressureStartLocal;
    pressureEnd = pressureEndLocal;

    prefs.setDouble('freqStart', freqStart);
    prefs.setDouble('freqEnd', freqEnd);
    prefs.setDouble('rTx', rTx);
    prefs.setDouble('coef0', coef0);
    prefs.setDouble('coef1', coef1);
    prefs.setDouble('coef2', coef2);
    prefs.setDouble('coef3', coef3);
    prefs.setDouble('coef4', coef4);
    prefs.setDouble('coef5', coef5);
    prefs.setDouble('coefOffSet', coefOffSet);
    prefs.setDouble('pressureStart', pressureStart);
    prefs.setDouble('pressureEnd', pressureEnd);
    globalCoef[0] = coef0Local;
    globalCoef[1] = coef1Local;
    globalCoef[2] = coef2Local;
    globalCoef[3] = coef3Local;
    globalCoef[4] = coef4Local;
    globalCoef[5] = coef5Local;
    globalCoef[6] = coefOffSetLocal;
    dev.log("saved");
  }

  Future<void> _load() async {
    try {
      setState(() {
        // ✅ SharedPreferences에서 불러오기
        freqStartLocal = prefs.getDouble('freqStart') ?? 36;
        freqEndLocal = prefs.getDouble('freqEnd') ?? 52;
        rTxLocal = prefs.getDouble('rTx') ?? 5;
        coef0Local = prefs.getDouble('coef0') ?? -57425;
        coef1Local = prefs.getDouble('coef1') ?? 3724;
        coef2Local = prefs.getDouble('coef2') ?? -80.03;
        coef3Local = prefs.getDouble('coef3') ?? 0.5711;
        coef4Local = prefs.getDouble('coef4') ?? 0;
        coef5Local = prefs.getDouble('coef5') ?? 0;
        coefOffSetLocal = prefs.getDouble('coefOffSet') ?? 5;
        pressureStartLocal = prefs.getDouble('pressureStart') ?? 0;
        pressureEndLocal = prefs.getDouble('pressureEnd') ?? 150;

        // ✅ data.dart 값도 동기화
        freqStart = freqStartLocal;
        freqEnd = freqEndLocal;
        rTx = rTxLocal;
        coef0 = coef0Local;
        coef1 = coef1Local;
        coef2 = coef2Local;
        coef3 = coef3Local;
        coef4 = coef4Local;
        coef5 = coef5Local;
        coefOffSet = coefOffSetLocal;
        pressureStart = pressureStartLocal;
        pressureEnd = pressureEndLocal;
        // ✅ TextField 컨트롤러 업데이트
        freqStartNumController.text = freqStartLocal.toString();
        freqEndNumController.text = freqEndLocal.toString();
        rTxController.text = rTxLocal.toString();
        coef0NumController.text = coef0Local.toString();
        coef1NumController.text = coef1Local.toString();
        coef2NumController.text = coef2Local.toString();
        coef3NumController.text = coef3Local.toString();
        coef4NumController.text = coef4Local.toString();
        coef5NumController.text = coef5Local.toString();
        coefOffSetNumController.text = coefOffSetLocal.toString();
        pressureStartNumController.text = pressureStartLocal.toString();
        pressureEndNumController.text = pressureEndLocal.toString();
        globalCoef[0] = coef0Local;
        globalCoef[1] = coef1Local;
        globalCoef[2] = coef2Local;
        globalCoef[3] = coef3Local;
        globalCoef[4] = coef4Local;
        globalCoef[5] = coef5Local;
        globalCoef[6] = coefOffSetLocal;
      });
    } catch (e) {
      dev.log("Load error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 19.5,
          child: Column(
            children: [
              margin(1), // s10의 경우 필요하다.
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.all(baseSize * 1),
                              // Connect 버튼
                              child: TextButton(
                                onPressed: () async {
                                  setState(() {});
                                  if (bluetoothConnectButtonStringIndex == 0) {
                                    dev.log("dialog on");
                                    showBleDeviceList();
                                    mainGraphData = initMainGraphData(150);
                                  } else {
                                    bleDeviceDisconnect();
                                  }
                                },
                                style: baseButton(),
                                child: AutoSizeText(
                                  buttonText[bluetoothConnectButtonStringIndex],
                                  style: TextStyle(
                                    fontSize: baseSize * 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                AutoSizeText(
                                  deviceEqual,
                                  style: connectButtonStyle(),
                                  minFontSize: 10,
                                  maxLines: 1,
                                ),
                                Expanded(
                                  child: AutoSizeText(
                                    connectedDeviceName,
                                    style: connectButtonStyle(),
                                    minFontSize: 10,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: EdgeInsets.all(baseSize * 1),
                              child: TextButton(
                                onPressed: () {
                                  showOptionDialog(context);
                                },
                                style: baseButton(),
                                child: AutoSizeText(
                                  "Option",
                                  style: TextStyle(
                                    fontSize: baseSize * 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: showZCheckBoxState,
                                  onChanged: (value) {
                                    showZCheckBoxState = value;
                                    if (showZCheckBoxState == true) {
                                      leftGraphTitle = 'zReal graph';
                                      rightGraphTitle = 'zImg graph';
                                    } else {
                                      leftGraphTitle = 'phase graph';
                                      rightGraphTitle = 'gain graph';
                                    }
                                    if (mounted) {
                                      setState(() {});
                                      dev.log('check box');
                                    }
                                  },
                                ),
                                Expanded(
                                  child: AutoSizeText(
                                    "Show Z",
                                    style: TextStyle(fontSize: baseSize * 1.5),
                                    minFontSize: 8,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: pressureCheckBoxState,
                                  onChanged: (value) {
                                    pressureCheckBoxState = value;
                                    if (pressureCheckBoxState == true) {
                                      yAxisMin = pressureEndLocal;
                                      yAxisMax = pressureStartLocal;
                                    } else {
                                      yAxisMin = freqStartLocal;
                                      yAxisMax = freqEndLocal;
                                    }
                                    if (mounted) {
                                      setState(() {});
                                      dev.log('check box');
                                    }
                                  },
                                ),
                                Expanded(
                                  child: AutoSizeText(
                                    "Pressure",
                                    style: TextStyle(fontSize: baseSize * 1.5),
                                    minFontSize: 8,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: EdgeInsets.all(baseSize * 1),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {});
                                  dev.log("press start button");
                                  try {
                                    if (isConnected && mounted) {
                                      !isGraphing ? startGraph() : stopGraph();
                                    }
                                  } catch (e) {
                                    dev.log("error : $e");
                                  }
                                },
                                style: baseButton(),
                                child: Text(
                                  !isGraphing ? startStr : stopStr,
                                  style: TextStyle(
                                    fontSize: baseSize * 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                // two graph, choose file, trend graph
                flex: 16,
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.only(right: baseSize * 1),
                        child: SfCartesianChart(
                          primaryYAxis: NumericAxis(
                            labelStyle:
                                TextStyle(fontSize: baseSize * graphNumber),
                          ),
                          primaryXAxis: NumericAxis(
                            title: AxisTitle(
                              text: 'freuquency(MHz)',
                              textStyle: TextStyle(fontSize: baseSize * 1.2),
                            ),
                            labelStyle:
                                TextStyle(fontSize: baseSize * graphNumber),
                          ),
                          title: ChartTitle(
                            text: leftGraphTitle,
                            textStyle: TextStyle(fontSize: baseSize * 1.2),
                          ),
                          series: <CartesianSeries>[
                            LineSeries<GraphData, double>(
                              markerSettings: const MarkerSettings(
                                shape: DataMarkerType.circle,
                                isVisible: true,
                                width: 4,
                                height: 4,
                              ),
                              color: Colors.blue,
                              onRendererCreated: (controller) =>
                                  phaseGraphController = controller,
                              dataSource: phaseGraphData,
                              xValueMapper: (GraphData data, _) => data.x,
                              yValueMapper: (GraphData data, _) => data.y,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.only(right: baseSize * 1),
                        child: SfCartesianChart(
                            primaryYAxis: NumericAxis(
                              labelStyle:
                                  TextStyle(fontSize: baseSize * graphNumber),
                            ),
                            primaryXAxis: NumericAxis(
                              title: AxisTitle(
                                text: 'freuquency(MHz)',
                                textStyle: TextStyle(fontSize: baseSize * 1.2),
                              ),
                              labelStyle:
                                  TextStyle(fontSize: baseSize * graphNumber),
                            ),
                            title: ChartTitle(
                              text: rightGraphTitle,
                              textStyle: TextStyle(fontSize: baseSize * 1.2),
                            ),
                            series: <CartesianSeries>[
                              LineSeries<GraphData, double>(
                                markerSettings: const MarkerSettings(
                                  shape: DataMarkerType.circle,
                                  isVisible: true,
                                  width: 4,
                                  height: 4,
                                ),
                                color: Colors.blue,
                                onRendererCreated: (controller) =>
                                    gainGraphController = controller,
                                dataSource: gainGraphData,
                                xValueMapper: (GraphData data, _) => data.x,
                                yValueMapper: (GraphData data, _) => data.y,
                              )
                            ]),
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "TX:",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: baseSize * 2),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              // file select button
                              child: Padding(
                                padding: EdgeInsets.only(right: baseSize * 1),
                                child: TextButton(
                                  style: baseButton(),
                                  onPressed: () {
                                    // 그래프가 그려지는 중이 아닐때만
                                    if (!isGraphing) {
                                      settingFileList();
                                      isFileSelected = false;
                                      showFileList();
                                    }
                                  },
                                  child: Text(
                                    selectedFilePath!,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: baseSize * 1.1),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: EdgeInsets.only(right: baseSize * 1),
                                child: Text(
                                  "HR: ${hrValue.toString().padLeft(3)}, "
                                  "SBP: ${sbpValue.toString().padLeft(3)}, "
                                  "DBP: ${dbpValue.toString().padLeft(3)}",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: baseSize * 1.5),
                                ),
                              ),
                              /*
                              child: DropdownButton<String>(
                                menuMaxHeight: 10,
                                onTap: () {
                                  getExternalStorageDirectoryPath()
                                      .then((directoryPath) {
                                    getFilesFromDirectory(tmpDirPath).then((Files) {
                                      Files.sort();
                                      Files.reversed;
                                      dev.log(Files.toString());
                                      filePaths = [
                                        "None : record only"
                                      ]; // 맨 처음은 무조건 None이 들어가야 하므로
                                      filePaths.addAll(Files);
                                      selectedFilePath = filePaths.first;
                                      dev.log(
                                          "file count : ${filePaths.length - 1}");

                                      // setState(() {});
                                    });
                                  });
                                  setState(() {});
                                },
                                padding: EdgeInsets.only(right: baseSize * 1),
                                alignment: Alignment.center,
                                value: selectedFilePath,
                                onChanged: onFileSelected,
                                items: filePaths
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ), */
                            ),
                          ],
                        )),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.only(right: baseSize * 1),
                        child: SfCartesianChart(
                          series: <CartesianSeries>[
                            LineSeries<MainGraphData, dynamic>(
                              color: Colors.red,
                              onRendererCreated: (controller) =>
                                  mainGraphController = controller,
                              dataSource: mainGraphData,
                              xValueMapper: (MainGraphData data, _) => data.x,
                              yValueMapper: (MainGraphData data, _) => data.y,
                              animationDuration: 0, // 애니메이션 비활성화
                            ),
                          ],
                          primaryXAxis: NumericAxis(
                            interval: 10,
                            minimum: 0,
                            maximum: 150,
                            labelStyle:
                                TextStyle(fontSize: baseSize * graphNumber),
                          ),
                          primaryYAxis: NumericAxis(
                            isInversed: !pressureCheckBoxState!,
                            minimum: yAxisMin.toDouble(),
                            maximum: yAxisMax.toDouble(),
                            labelStyle:
                                TextStyle(fontSize: baseSize * graphNumber),
                          ),
                          tooltipBehavior: TooltipBehavior(enable: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // -- for connect button ------------
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

  settingFileList() {
    getExternalStorageDirectoryPath().then((directoryPath) {
      getFilesFromDirectory(tmpDirPath).then((Files) {
        Files.sort();
        dev.log(Files.toString());
        Files = Files.reversed.toList();
        setState(() {
          filePathList = ["None : record only"]; // 맨 처음은 무조건 None이 들어가야 하므로
          for (String _fileName in Files) {
            // trend.txt 파일은 표시하지 않는다.
            if (!_fileName.contains('trend')) {
              filePathList.add(_fileName);
            }
          }
          // filePathList.addAll(Files);
          // 기존에 선택된 파일이 있다면 그대로 유지한다.
          if (!isFileSelected) {
            selectedFilePath = filePathList.first;
          }
        });
      });
    });
  }

  // for choose file button ---------
  showFileList() async {
    if (mounted) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: SizedBox(
                height: double.maxFinite,
                width: baseSize * 33,
                child: ListView.separated(
                  itemCount: filePathList.length,
                  itemBuilder: (context, index) {
                    return fileListItem(filePathList[index], context);
                  },
                  separatorBuilder: (context, index) => const Divider(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('닫기'),
                ),
              ],
            );
          });
    }
  }

  void showOptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, dialogSetState) {
          return AlertDialog(
            title: Text("Option", style: TextStyle(fontSize: baseSize * 2.5)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Freq Start
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Freq Start",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: freqStartNumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),

                  // Freq End
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Freq End",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: freqEndNumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),

                  // Num Sweep Point (Disabled)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Num Sweep Point ",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            textAlign: TextAlign.center,
                            enabled: false, // 수정 불가능
                            controller: numSweepPointNumController,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),

                  // Update Interval
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Update Interval",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: updateIntervalController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),

                  // rTx
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "rTx",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: rTxController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // coef0
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "x^0 coef",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: coef0NumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // coef1
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "x^1 coef",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: coef1NumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // coef2
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "x^2 coef",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: coef2NumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // coef3
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "x^3 coef",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: coef3NumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // coef4
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "x^4 coef",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: coef4NumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // coef5
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "x^5 coef",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: coef5NumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // coefOffSet
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "x^0 offset",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: InkWell(
                            onTap: () {
                              showCupertinoModalPopup<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    color: Colors.white,
                                    height: 300,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                // 옵션 다이얼로그 UI 갱신
                                                dialogSetState(() {});
                                              },
                                              child: const Text("확인"),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 1),
                                        Expanded(
                                          child: CupertinoPicker(
                                            scrollController:
                                                FixedExtentScrollController(
                                              initialItem:
                                                  50 + coefOffSet.toInt(),
                                            ),
                                            itemExtent: 36,
                                            onSelectedItemChanged: (int index) {
                                              setState(() {
                                                coefOffSet =
                                                    (index - 50).toDouble();
                                                coefOffSetNumController.text =
                                                    coefOffSet.toString();
                                              });
                                            },
                                            children: List<Widget>.generate(101,
                                                (int index) {
                                              final int value = index - 50;
                                              return Center(
                                                  child:
                                                      Text(value.toString()));
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ).then((_) {
                                // CupertinoPicker가 닫힐 때 옵션 다이얼로그 UI 갱신
                                dialogSetState(() {});
                              });
                            },
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '$coefOffSet',
                                style: TextStyle(fontSize: baseSize * 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: baseSize * 1),
                  // pressure start
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "pressure start",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: pressureStartNumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: baseSize * 1),
                  // pressure end
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "pressure end",
                          style: TextStyle(fontSize: baseSize * 1.35),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: baseSize * 1, top: baseSize * 0.2),
                          child: TextField(
                            style: TextStyle(fontSize: baseSize * 2),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: pressureEndNumController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 변경된 값 적용
                  setState(() {
                    freqStartLocal =
                        double.tryParse(freqStartNumController.text) ??
                            freqStartLocal;
                    freqEndLocal = double.tryParse(freqEndNumController.text) ??
                        freqEndLocal;
                    updateIntervalLocal =
                        int.tryParse(updateIntervalController.text) ??
                            updateIntervalLocal;
                    rTxLocal = double.tryParse(rTxController.text) ?? rTxLocal;
                    coef0Local =
                        double.tryParse(coef0NumController.text) ?? coef0Local;
                    coef1Local =
                        double.tryParse(coef1NumController.text) ?? coef1Local;
                    coef2Local =
                        double.tryParse(coef2NumController.text) ?? coef2Local;
                    coef3Local =
                        double.tryParse(coef3NumController.text) ?? coef3Local;
                    coef4Local =
                        double.tryParse(coef4NumController.text) ?? coef4Local;
                    coef5Local =
                        double.tryParse(coef5NumController.text) ?? coef5Local;
                    coefOffSetLocal =
                        double.tryParse(coefOffSetNumController.text) ??
                            coefOffSetLocal;

                    pressureStartLocal =
                        double.tryParse(pressureStartNumController.text) ??
                            pressureStartLocal;
                    pressureEndLocal =
                        double.tryParse(pressureEndNumController.text) ??
                            pressureEndLocal;

                    freqStart = freqStartLocal;
                    freqEnd = freqEndLocal;
                    graphUpdateInterval = updateIntervalLocal;
                    rTx = rTxLocal;
                    coef0 = coef0Local;
                    coef1 = coef1Local;
                    coef2 = coef2Local;
                    coef3 = coef3Local;
                    coef4 = coef4Local;
                    coef5 = coef5Local;
                    coefOffSet = coefOffSetLocal;
                    pressureStart = pressureStartLocal;
                    pressureEnd = pressureEndLocal;
                    if (pressureCheckBoxState == true) {
                      yAxisMin = pressureEndLocal;
                      yAxisMax = pressureStartLocal;
                    } else {
                      yAxisMin = freqStartLocal;
                      yAxisMax = freqEndLocal;
                    }
                  });
                  _save();
                  Navigator.of(context).pop(); // 옵션 창 닫기
                },
                child: Text("Close", style: TextStyle(fontSize: baseSize * 2)),
              ),
            ],
          );
        });
      },
    );
  }

  void updateComputeValue(List<double> buf) async {
    // computeValueIsolate를 별도 isolate에서 돌리고,
    // 결과를 받아옴
    final resultMap = await compute(computeValueIsolate, [buf, globalCoef]);

    // UI에 반영해야 한다면 setState로 값 업데이트
    setState(() {
      hrValue = resultMap['HR']!.toInt();
      sbpValue = resultMap['SBP']!.toInt();
      dbpValue = resultMap['DBP']!.toInt();
    });
  }

  void onFileSelected(String? filePath) async {
    dev.log("filePath in onFileSelected : $filePath");

    if (filePath == "None : record only") {
      dev.log("isRecOnly is false");
      isFileSelected = false;
    } else {
      dev.log("isRecOnly is true");
      isFileSelected = true;
      selectedFilePath = filePath;
      // TXfile = File(selectedFilePath!).readAsStringSync();

      TX = TxBaseLine();
      TX.initFromFile(selectedFilePath!);
      // TX.initFilter(5, 1.5);
      // TX.initMatResample((TX.numPoint - 1) * 200 + 1);
      // TX.initFilter(5, 1.0);
      TX.initFilter(7, 0.2);
      TX.initMatResample((TX.numPoint - 1) * 800 + 1);

      dev.log("txZRealMean : ${TX.txZRealMean}");
      dev.log("txZImagMean : ${TX.txZImagMean}");
      // call back
    }
    dev.log("selected file path : '${filePath.toString()}'");
    dev.log("isRecOnly : $isFileSelected");
  }

  int maxTime = 0; // 가장 오래 걸리는 콜백 함수는 몇 ms 인지 알기 위해서
  late int totalCount; // 콜백 함수의 평균 실행 시간을 구하기 위함
  late double averageTime; // 콜백 함수의 평균 실행 시간

  List<MainGraphData> MainGraphFreq = initMainGraphData(150);
  List<MainGraphData> MainGraphPres = initMainGraphData(150);

  startGraph() async {
    dev.log("start graph");
    fileDataBuffer = '';
    trendFileDataBuffer = '';
    dataReceiveCount = 0;
    fileDataCount = 0;
    totalCount = 1;
    averageTime = 0.0;
    bool isFirst = true;

    sink = await makeFile(); // 파일과의 연결고리 생성
    dev.log("sink state : ${sink.done.toString()}");
    // 각각의 속성을 상단에 write 한다.

    // TX File이 선택된 경우 trend 파일을 만들기 위한 추가적인 IOSink를 만들어야 한다.
    if (isFileSelected) {
      trendSink = await makeTrendFile();
      trendSink.write('$selectedFilePath\n');
    }

    setState(() {
      isGraphing = true;
    });

    mainGraphX = 0;
    mainGraphData = initMainGraphData(150);

    late DateTime dataReceiveTime;
    int dataLen = 0;
    // List<int> dataList = [];
    // int totalDataLen = (8 * numSweepPoint) + 1; // 1은 맨 앞에 0

    await heartRateMeasurementCharcteristic.setNotifyValue(true).then((value) {
      dev.log("set notify value");
    });

    stream =
        heartRateMeasurementCharcteristic.onValueReceived.listen((dataList) {
      if (isFirst) {
        setState(() {});
        // 기존에 numSweepPoint를 이용해 초기화 한 것을 지워낸다.
        dev.log("numSweepPoint : $numSweepPoint");
        for (int i = 0; i < numSweepPoint; i++) {
          gainGraphData.removeAt(0);
          phaseGraphData.removeAt(0);

          gainGraphController.updateDataSource(removedDataIndex: 0);
          phaseGraphController.updateDataSource(removedDataIndex: 0);
        }

        // 입력받은 데이터를 이용하여 실제 numSweepPoint를 알아낸 후, 그래프를 업데이트 해준다.
        int len = dataList.length;
        dataLen = (len - 1) ~/ 8;

        sink.write('$freqStartLocal $freqEndLocal $dataLen\n');
        numSweepPointNumController.text = dataLen.toString();
        numSweepPoint = dataLen;

        isFirst = false;

        xInterval = (freqEndLocal - freqStartLocal) / (dataLen - 1);
        xValue = freqStartLocal.toDouble();
        for (int i = 0; i < dataLen; i++) {
          gainGraphData.add(GraphData(xValue, 0));
          phaseGraphData.add(GraphData(xValue, 0));
          xValue += xInterval;

          gainGraphController.updateDataSource(
              addedDataIndex: gainGraphData.length - 1);
          phaseGraphController.updateDataSource(
              addedDataIndex: phaseGraphData.length - 1);
        }
        setState(() {});
      }
      // 데이터를 받자마자 바로 시간을 기록한다.
      dataReceiveTime = DateTime.now();

      trendFileDataBuffer += dataReceiveTime.toString();

      // 변경사항 : (phase, gain)이 (2, 2)가 아닌, (4, 4)로 전달된다.

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

      ////////////////// hj ///////////////////

      /////////////////////////////////////////

      // received data from BLE device.
      // for (int i = 1; i < len; i += 4) {
      //   phaseOriginData.add(dataList[i] + dataList[i + 1] * 256);
      //   gainOriginData.add(dataList[i + 2] + dataList[i + 3] * 256);
      // }

      // 변경사항 반영하기 = 4,4 바이트의 데이터를 decoding하는 방식이다.
      for (int i = 1; i < dataList.length; i += 8) {
        int phaseData = dataList[i + 0] * 1 +
            dataList[i + 1] * 256 +
            dataList[i + 2] * 65536 +
            dataList[i + 3] * 16777216;
        phaseOriginData.add(phaseData);

        int gainData = dataList[i + 4] * 1 +
            dataList[i + 5] * 256 +
            dataList[i + 6] * 65536 +
            dataList[i + 7] * 16777216;
        gainOriginData.add(gainData);

        // int phaseData = dataList[i + 0] * 16777216 +
        //     dataList[i + 1] * 65536 +
        //     dataList[i + 2] * 256 +
        //     dataList[i + 3] * 1;
        // phaseOriginData.add(phaseData);

        // int gainData = dataList[i + 4] * 16777216 +
        //     dataList[i + 5] * 65536 +
        //     dataList[i + 6] * 256 +
        //     dataList[i + 7] * 1;
        // gainOriginData.add(gainData);

        // dev.log("phase : $phaseData, gain : $gainData");
      }

      fileDataBuffer += DateTime.now().toString();
      for (int i = 0; i < dataLen; i++) {
        fileDataBuffer +=
            ' ${phaseOriginData[i].toString()} ${gainOriginData[i].toString()}';
      }
      fileDataBuffer += '\n';
      // dev.log("dataList : $dataList");
      // dev.log("dataList.length : ${dataList.length}");

      //  original data processing
      for (int i = 0; i < dataLen; i++) {
        phaseValue = phaseOriginData[i].toDouble();
        gainValue = gainOriginData[i].toDouble();

        phaseValue *= (1.8 / 2147483648);
        phaseProcessedData.add(phaseValue / 0.01);

        gainValue *= (1.8 / 2147483648);
        gainValue = -30 + (gainValue / 0.03);
        gainProcessedData.add(pow(10, (gainValue / 20)).toDouble());
      }

      // z data processing
      for (int i = 0; i < dataLen; i++) {
        double gainTx = gainProcessedData[i];
        double phaseTx = phaseProcessedData[i];

        zRealData.add((gainTx * cos(pi - (phaseTx * pi / 180)) - 1) * rTxLocal);
        zImgData.add((gainTx * sin(pi - (phaseTx * pi / 180))) * rTxLocal);
      }

      // draw graph using origin data
      // for (int i = 0; i < dataLen; i++) {
      //   phaseGraphData.add(GraphData(dataCnt, phaseOriginData[i].toDouble()));
      //   gainGraphData.add(GraphData(dataCnt, gainOriginData[i].toDouble()));
      //   phaseGraphData.removeAt(0);
      //   gainGraphData.removeAt(0);
      //   phaseGraphController.updateDataSource(
      //       addedDataIndex: phaseGraphData.length - 1, removedDataIndex: 0);
      //   gainGraphController.updateDataSource(
      //       addedDataIndex: gainGraphData.length - 1, removedDataIndex: 0);
      //   dataCnt++;
      // }

      if (isFileSelected) {
        var txrxZReal = Array(zRealData);
        // var txrxZImag = Array(zImgData);

        Array zReal = txrxZReal - TX.txZRealMean;
        // Array zImag = txrxZImag - TX.txZImagMean;

        Array zrealFilt = TX.convFilter(zReal);
        Array zrealInterp = TX.matInterp(zrealFilt);

        double resFreq = TX.getPeakFrequencyFromResample(zrealInterp);
        double resPres = coef0Local * pow(resFreq, 0) +
            coef1Local * pow(resFreq, 1) +
            coef2Local * pow(resFreq, 2) +
            coef3Local * pow(resFreq, 3) +
            coef4Local * pow(resFreq, 4) +
            coef5Local * pow(resFreq, 5) +
            coefOffSetLocal;

        // mainGraphY = resFreq;
        // mainGraphData[mainGraphX] = MainGraphData(mainGraphX, mainGraphY);
        // mainGraphX = (mainGraphX + 1) % 150;
        // mainGraphData[mainGraphX] = MainGraphData(mainGraphX, null);
        // mainGraphController!.updateDataSource();

        //////////////////////// hj ///////////////////
        MainGraphFreq[mainGraphX] = MainGraphData(mainGraphX, resFreq);
        MainGraphPres[mainGraphX] = MainGraphData(mainGraphX, resPres);
        mainGraphX = (mainGraphX + 1) % 150;
        MainGraphFreq[mainGraphX] = MainGraphData(mainGraphX, null);
        MainGraphPres[mainGraphX] = MainGraphData(mainGraphX, null);

        // mainGraphData = MainGraphPres;
        if (pressureCheckBoxState == true) {
          mainGraphData = MainGraphPres;
        } else {
          mainGraphData = MainGraphFreq;
        }

        mainGraphController!.updateDataSource();
        /////////////

        trendFileDataBuffer += ' ${resFreq.toStringAsFixed(2)}\n';

        ////////////////////////// jh ///////////////////////////
        calcBuffer.add(resFreq);
        if (calcBuffer.length >= 40 * 5) {
          print("buffer_if");
          List<double> tmpBuffer = List.from(calcBuffer);
          // computeValue에서 HR, SBP, DBP 값을 반환받기
          updateComputeValue(tmpBuffer);
          calcBuffer.removeRange(0, 40);
        }

        /////////////////////////////////////////////////////////
      }

      // 무조건 그래프를 업데이트 하는 것은 dataReceivedCount이 graphUpdateInterval에 도달할때 마다 만 업데이트 한다.
      // dev.log(
      //     "dataReceivedCount : $dataReceiveCount, graphUpdateInterval : $graphUpdateInterval");
      if (dataReceiveCount >= graphUpdateInterval) {
        dataReceiveCount = 0;
        // dev.log("update");
        // z data를 사용할지 여부를 결정
        xValue = freqStartLocal.toDouble();
        if (showZCheckBoxState == true) {
          // draw graph usig z data
          for (int i = 0; i < dataLen; i++) {
            if (isFileSelected) {
              phaseGraphData
                  .add(GraphData(xValue, zRealData[i] - TX.txZRealMean[i]));
              gainGraphData
                  .add(GraphData(xValue, zImgData[i] - TX.txZImagMean[i]));
            } else {
              phaseGraphData.add(GraphData(xValue, zRealData[i]));
              gainGraphData.add(GraphData(xValue, zImgData[i]));
            }

            phaseGraphData.removeAt(0);
            gainGraphData.removeAt(0);

            phaseGraphController.updateDataSource(
                addedDataIndex: phaseGraphData.length - 1, removedDataIndex: 0);
            gainGraphController.updateDataSource(
                addedDataIndex: gainGraphData.length - 1, removedDataIndex: 0);

            xValue += xInterval;
          }
        } else {
          xValue = freqStartLocal.toDouble();
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

            xValue += xInterval;
          }
        }

        setState(() {});
      } else {
        // dev.log("not");
        dataReceiveCount++;
      }

      if (fileDataCount >= fileWriteInterval) {
        fileDataCount = 0;
        // updateHRValue();
        sink.write(fileDataBuffer);
        fileDataBuffer = '';
        // TX File이 선택된 경우에만
        if (isFileSelected) {
          trendSink.write(trendFileDataBuffer);
          trendFileDataBuffer = '';
        }
      } else {
        fileDataCount++;
      }

      xValue = freqStartLocal.toDouble();
      // DateTime endtime = DateTime.now();
      final executionTime = DateTime.now().difference(dataReceiveTime);
      // // 이동 평균을 사용하여 평균을 계산(더 효율적)
      // dev.log("execution time : ${executionTime.inMilliseconds}ms");
      // averageTime =
      //     ((averageTime * (totalCount - 1)) + executionTime.inMilliseconds) /
      //         totalCount++;
      maxTime = max(maxTime, executionTime.inMilliseconds);
    });
  }

  stopGraph() async {
    stream.cancel();
    heartRateMeasurementCharcteristic.setNotifyValue(false);
    setState(() {
      isGraphing = false;
    });

    // // 파일과의 연결고리를 만드는 부분, start와 동시에 연결고리 생성
    // IOSink sink = await makeFile(); // 파일과의 연결고리
    // dev.log("sink state : ${sink.done.toString()}");

    sink.write(fileDataBuffer);
    // dev.log("fileDataBuffer length : ${fileDataBuffer.length}");
    sink.close();

    if (isFileSelected) {
      trendSink.close();
    }

    settingFileList();
    positiveToast("file save to $filePath");
    setState(() {});

    dev.log("가장 오래 걸린 콜백함수의 시간 : ${maxTime}ms");
    dev.log("콜백 함수 평균 실행시간 : ${averageTime}ms");
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

  Future<IOSink> makeTrendFile() async {
    await checkPermission();

    tmpDirectory = Directory(tmpDirPath);

    if (!tmpDirectory.existsSync()) {
      await tmpDirectory.create();
    }

    // getFileName 함수의 반환 값 예시 : 240705_151513
    filePath = '$tmpDirPath/${getTrendFileName()}';
    file = File(filePath);
    dev.log('created file path : $filePath');

    return file.openWrite(mode: FileMode.writeOnly);
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

  Widget fileListItem(String fileName, BuildContext dialogContext) {
    return ListTile(
      onTap: () {
        selectedFilePath = fileName;
        setState(() {});
        positiveToast("selected file name : $selectedFilePath");
        onFileSelected(fileName);
        Navigator.of(dialogContext).pop();
      },
      leading: fileLeading(fileName),
      title: Text(fileName),
    );
  }
}

settingParameterText(String title) {
  return FittedBox(
    fit: BoxFit.fitWidth,
    child: Text(
      textAlign: TextAlign.center,
      title,
      style: settingParameterTextStyle(),
    ),
  );
}

settingParameterStrutStyle() {
  return const StrutStyle();
}

settingParameterTextStyle() {
  return TextStyle(
    fontSize: baseSize * 1.4,
  );
}

/*
SfCartesianChart(
              series: <LineSeries<MainGraphData, dynamic>>[
                LineSeries(
                  onRendererCreated: (controller) =>
                      mainGraphController = controller,
                  dataSource: mainGraphData,
                  emptyPointSettings:
                      const EmptyPointSettings(mode: EmptyPointMode.gap),
                  xValueMapper: (MainGraphData data, _) => data.x,
                  yValueMapper: (MainGraphData data, _) => data.y,
                )
              ],
              primaryXAxis: const NumericAxis(
                interval: 10,
                minimum: 0,
                maximum: 150,
              ),
            ),
*/
ButtonStyle baseButton() {
  return ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    backgroundColor: const WidgetStatePropertyAll(Colors.deepPurple),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
