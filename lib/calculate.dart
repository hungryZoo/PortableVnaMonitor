// // import 'package:dart_singal_processing/dart_singal_processing.dart'
// //     as dart_singal_processing;
// import 'package:scidart/scidart.dart';
// import 'package:scidart/numdart.dart';
// import 'package:scidart_io/scidart_io.dart';
// import 'package:scidart_plot/scidart_plot.dart';
// import 'dart:async';
// import 'dart:io';

// Array array2dMean(Array2d mat, {int axis = 0}) {
//   Array tmp = Array.empty();
//   if (axis == 0) {
//     mat = matrixTranspose(mat);
//   }

//   for (var i = 0; i < mat.row; i++) {
//     tmp.add(mean(mat[i]));
//   }
//   return tmp;
// }

// class TxBaseLine {
//   String fileName = "";
//   double startFreq = 0.0;
//   double endFreq = 0.0;
//   int numPoint = 0;
//   Array txZRealMean = Array.empty();
//   Array txZImagMean = Array.empty();

//   void initFromFile(String fileName) {
//     /** File Read */
//     List<String> txtFile = File(fileName).readAsLinesSync();

//     /** Get Info Header */
//     var infoList = txtFile[0].split(" ").map(double.parse).toList();
//     var startFreq = infoList[0];
//     var endFreq = infoList[1];
//     var numPoint = infoList[2].toInt();
//     var numSample = txtFile.length - 1;

//     /** parse time */
//     // var txDataTimeStamp =
//     //   List<DateTime>.empty(growable: true); // todo:fixed len list
//     // for (var i = 1; i < txtFile.length; i++) {
//     //   String tmpDt = txtFile[i].substring(0, 26);
//     //   txDataTimeStamp.add(DateTime.parse(tmpDt));
//     // }

//     /** Parse phase,gain */
//     var txPhase = Array2d.fixed(numSample, numPoint);
//     var txGain = Array2d.fixed(numSample, numPoint);
//     for (var i = 1; i < txtFile.length; i++) {
//       String tmpData = txtFile[i].substring(27);
//       List<double> dataList = tmpData.split(" ").map(double.parse).toList();

//       int nPoint = (dataList.length ~/ 2);
//       var tmpPhase = Array.fixed(numPoint);
//       var tmpGain = Array.fixed(numPoint);
//       for (var j = 0; j < nPoint; j++) {
//         tmpPhase[j] = dataList[2 * j + 0];
//         tmpGain[j] = dataList[2 * j + 1];
//       }
//       txPhase[i - 1] = (tmpPhase);
//       txGain[i - 1] = (tmpGain);
//     }

//     /** calculate phase, gain */
//     for (var i = 0; i < numSample; i++) {
//       for (var j = 0; j < numPoint; j++) {
//         txPhase[i][j] *= (1.8 / 16384);
//         txPhase[i][j] /= 0.01;
//       }
//     }

//     for (var i = 0; i < txGain.row; i++) {
//       for (var j = 0; j < txGain.column; j++) {
//         txGain[i][j] *= (1.8 / 16384);
//         txGain[i][j] = -30 + (txGain[i][j] / 0.03);
//         txGain[i][j] = pow(10, (txGain[i][j] / 20)).toDouble();
//       }
//     }

//     /** Convert Z */
//     var txZReal = Array2d.fixed(numSample, numPoint);
//     var txZImag = Array2d.fixed(numSample, numPoint);
//     double rTx = 5;

//     for (var i = 0; i < numSample; i++) {
//       for (var j = 0; j < numPoint; j++) {
//         txZReal[i][j] =
//             (txGain[i][j] * cos(pi - (txPhase[i][j] * pi / 180)) - 1) * rTx;
//         txZImag[i][j] =
//             (txGain[i][j] * sin(pi - (txPhase[i][j] * pi / 180)) - 0) * rTx;
//       }
//     }

//     /** Average 2D */
//     txZRealMean = array2dMean(txZReal);
//     txZImagMean = array2dMean(txZImag);

//     /** Init Self */
//     this.fileName = fileName;
//     this.startFreq = startFreq;
//     this.endFreq = endFreq;
//     this.numPoint = numPoint;
//     txZRealMean = txZRealMean.copy();
//     txZImagMean = txZImagMean.copy();
//   }
// }

// void main(List<String> arguments) {
//   var a = TxBaseLine();
//   a.initFromFile("test/240702_195507.txt");
//   print(a.txZRealMean);
//   print(a.txZImagMean);

//   var line1 = PlotGeneral(
//       ay: a.txZRealMean,
//       plotGeneralType: PlotGeneralType.Line,
//       stroke: Color.blue);
//   var line2 = PlotGeneral(
//       ay: a.txZImagMean,
//       plotGeneralType: PlotGeneralType.Line,
//       stroke: Color.orange);

//   var legend1 = LegendItem("txZRealMean");
//   var legend2 = LegendItem("txZImagMean");

//   var plotExample = canvasGeneral(
//       ax: linspace(a.startFreq, a.endFreq, num: a.numPoint, endpoint: true),
//       lines: [line1, line2],
//       title: 'Example plot',
//       legend: Legend([legend1, legend2], LegendPosition.topRight));
//   // plotExample.toXML()
//   // print(plotExample.toXML());
//   saveSvg(plotExample, "test/test.svg");
// }

// Future<void> saveSvg(SvgCanvas svgCanvas, String fileName) async {
//   const extension = '.svg';
//   if (!fileName.toLowerCase().endsWith(extension)) {
//     fileName += extension;
//   }
//   await writeTxt(svgCanvas.toXML(), fileName);
// }
