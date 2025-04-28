import 'dart:async';
import 'dart:io';
import 'dart:ui' as u;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// import 'package:pvm_col/calculate.dart';
import 'test3.dart';

late u.Size size;
late double baseSize;

late SharedPreferences prefs;

class GraphData {
  GraphData(this.x, this.y);

  final double x;
  final double y;
}

class MainGraphData {
  MainGraphData(this.x, this.y);

  final int x;
  final dynamic y; // nullable
}

// data for graph
List<GraphData> gainGraphData = [];
List<GraphData> phaseGraphData = [];
late ChartSeriesController gainGraphController;
late ChartSeriesController phaseGraphController;
bool isGraphing = false;

// bluetooth connect button
List<String> buttonText = ['Connect', 'Connected'];
int bluetoothConnectButtonStringIndex = 0;
String connectedDeviceName = "None";
String deviceEqual = "Device : ";
bool isConnected = false;
late ScanResult selectedDevice;

// toggle button
// bool isToggle = true;

// setting parameter button
String freqStartStr = '';
String freqEndStr = '';
String numSweepPointStr = '';
String updateIntervalStr = '';
double freqStart = 36;
double freqEnd = 54;
// int numSweepPoint = 11;
int numSweepPoint = 0;
double rTx = 5;
double coef0 = -57425;
double coef1 = 3724;
double coef2 = -80.03;
double coef3 = 0.5711;
double coef4 = 0;
double coef5 = 0;
double coefOffSet = 5;
double pressureStart = 0;
double pressureEnd = 150;

List<double> globalCoef = List.filled(7, 0.0);

TextEditingController freqStartNumController =
    TextEditingController(text: freqStart.toString());
TextEditingController freqEndNumController =
    TextEditingController(text: freqEnd.toString());
TextEditingController numSweepPointNumController =
    TextEditingController(text: numSweepPoint.toString());
TextEditingController updateIntervalController =
    TextEditingController(text: graphUpdateInterval.toString());
TextEditingController rTxController =
    TextEditingController(text: rTx.toString());
TextEditingController coef1NumController =
    TextEditingController(text: coef1.toString());
TextEditingController coef2NumController =
    TextEditingController(text: coef2.toString());
TextEditingController coef3NumController =
    TextEditingController(text: coef3.toString());
TextEditingController coef4NumController =
    TextEditingController(text: coef4.toString());
TextEditingController coef5NumController =
    TextEditingController(text: coef5.toString());
TextEditingController coefOffSetNumController =
    TextEditingController(text: coefOffSet.toString());
TextEditingController coef0NumController =
    TextEditingController(text: coef0.toString());
TextEditingController pressureStartNumController =
    TextEditingController(text: pressureStart.toString());
TextEditingController pressureEndNumController =
    TextEditingController(text: pressureEnd.toString());

// data for startButton
String startStr = 'Start';
String stopStr = 'Stop & Save';

// data for file
late IOSink sink;
String fileDataBuffer = '';
int fileDataCount = 0;
int fileWriteInterval = 100;
double xValue = 0;
double xInterval = 0;
late File file;
late String filePath;
late Directory tmpDirectory;
String tmpDirPath = "/storage/emulated/0/Download/tmp"; // Download의 tmp 디렉터리

// data for trend file
String trendFileDataBuffer = '';
late IOSink trendSink;

// data for bluetooth
late BluetoothCharacteristic heartRateMeasurementCharcteristic;
late StreamSubscription<List<int>> stream;

// data for checkbox
bool? showZCheckBoxState = false; // 기본 상태는 null
bool? pressureCheckBoxState = false; // 기본 상태는 null
String leftGraphTitle = 'phase graph';
String rightGraphTitle = 'gain graph';

// data for dialog
final List<int> bleIdList = [];
final List<ScanResult> bluetoothScanResult = [];

// data for main graph
bool isFileSelected = false;
// ignore: non`_`constant_identifier_names
late TxBaseLine TX;
int mainGraphX = 0;
// ignore: non_constant_identifier_names
String TXfile = "";
List<MainGraphData> mainGraphData = [];
late ChartSeriesController? mainGraphController;
double mainGraphY = 2; // 계산 이후의 값이 저장되는 변수

int graphUpdateInterval = 1; // 그래프를 몇번에 한번씩 업데이트 할 것인가?
int dataReceiveCount = 0;

// data for choose file
String? selectedFilePath = "None : record only";
List<String> filePathList = ["None : record only"];

// data for unity(통일)
double graphNumber = 1.4;
