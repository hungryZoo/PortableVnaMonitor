import 'dart:async';
import 'dart:io';

import 'package:pvm_col/data.dart';
import 'package:scidart/numdart.dart';
import 'package:scidart/scidart.dart';
import 'package:scidart_io/scidart_io.dart';
import 'package:scidart_plot/scidart_plot.dart';

Array array2dMean(Array2d mat, {int axis = 0}) {
  Array tmp = Array.empty();
  if (axis == 0) {
    mat = matrixTranspose(mat);
  }

  for (var i = 0; i < mat.row; i++) {
    tmp.add(mean(mat[i]));
  }
  return tmp;
}

Array ifftshift(Array inArray) {
  var tmp = Array.empty();
  tmp.addAll(inArray.sublist(inArray.length ~/ 2));
  tmp.addAll(inArray.sublist(0, inArray.length ~/ 2));
  return tmp;
}

class TxBaseLine {
  String fileName = "";
  double startFreq = 0.0;
  double endFreq = 0.0;
  int numPoint = 0;
  Array txZRealMean = Array.empty();
  Array txZImagMean = Array.empty();

  Array zRealFiltKernel = Array.empty();

  Array matResampleFilter = Array.empty();
  int padL = 0;
  int targetPoint = 0;

  Array resampleFreq = Array.empty();

  void initFilter(int order, double wn) {
    zRealFiltKernel = firwin(5, Array([wn / (numPoint / 2)])).copy();
  }

  void initMatResample(int targetPoint) {
    this.targetPoint = targetPoint;
    resampleFreq =
        linspace(startFreq, endFreq, num: targetPoint, endpoint: true);

    /** Design LPF */
    padL = (numPoint - 1) + numPoint + (numPoint - 1);
    matResampleFilter = ifftshift(blackman(padL)).copy();
  }

  Array convFilter(Array inArray) {
    var tmp = convolution(inArray, zRealFiltKernel);
    tmp = Array(tmp.sublist(2, 2 + numSweepPoint)); // 여기서 sweepPoint 값을 사용한다.
    return tmp;
  }

  Array matResample(Array inArray) {
    /** Padding */
    var tmp = Array.empty();
    tmp.addAll(inArray.sublist(1).reversed.toList());
    tmp.addAll(inArray);
    tmp.addAll(inArray.sublist(0, inArray.length - 1).reversed.toList());

    /** Resampling */
    /** fft */
    var tmp2 = fft(arrayToComplexArray(tmp));
    /** filter */
    tmp2 = tmp2 * arrayToComplexArray(matResampleFilter);
    /** Zero Insert Simple Version*/
    // tmp2.insertAll((this.padL / 2).ceil(),
    // ArrayComplex.fixed((3 * (targetPoint - 1) + 1) - this.padL));

    /** Zero Insert Optimized Version*/
    var tmp22 = ArrayComplex.fixed((3 * (targetPoint - 1) + 1));
    for (var i = 0; i < (padL / 2).ceil(); i++) {
      tmp22[i] = tmp2[i];
    }
    for (var i = 0; i < (padL / 2).floor(); i++) {
      tmp22[i + tmp22.length - (padL / 2).floor()] =
          tmp2[i + (padL / 2).ceil()];
    }
    tmp2 = tmp22;

    /** ifft */
    tmp2 = ifft(tmp2);

    /** Get Real part */
    var tmp3 = Array.fixed(tmp2.length);
    for (var i = 0; i < tmp3.length; i++) {
      tmp3[i] = tmp2[i].real;
    }

    /** Amplifying */
    tmp3 = arrayMultiplyToScalar(tmp3, tmp3.length / padL);

    /** Slicing Main Signal */
    var outputInterp =
        Array(tmp3.sublist(targetPoint - 1, targetPoint + (targetPoint - 1)));

    return outputInterp;
  }

  double getPeakFrequencyFromResample(Array inArray) {
    int idx = arrayArgMax(inArray);
    return resampleFreq[idx];
  }

  void initFromFile(String fileName) {
    /** File Read */
    List<String> txtFile = File(fileName).readAsLinesSync();

    /** Get Info Header */
    var infoList = txtFile[0].split(" ").map(double.parse).toList();
    var startFreq = infoList[0];
    var endFreq = infoList[1];
    var numPoint = infoList[2].toInt();
    var numSample = txtFile.length - 1;

    /** parse time */
    // var txDataTimeStamp =
    //   List<DateTime>.empty(growable: true); // todo:fixed len list
    // for (var i = 1; i < txtFile.length; i++) {
    //   String tmpDt = txtFile[i].substring(0  , 26);
    //   txDataTimeStamp.add(DateTime.parse(tmpDt));
    // }

    /** Parse phase,gain */
    var txPhase = Array2d.fixed(numSample, numPoint);
    var txGain = Array2d.fixed(numSample, numPoint);
    for (var i = 1; i < txtFile.length; i++) {
      String tmpData = txtFile[i].substring(27);
      List<double> dataList = tmpData.split(" ").map(double.parse).toList();

      int nPoint = (dataList.length ~/ 2);
      var tmpPhase = Array.fixed(numPoint);
      var tmpGain = Array.fixed(numPoint);
      for (var j = 0; j < nPoint; j++) {
        tmpPhase[j] = dataList[2 * j + 0];
        tmpGain[j] = dataList[2 * j + 1];
      }
      txPhase[i - 1] = tmpPhase.copy();
      txGain[i - 1] = tmpGain.copy();
    }

    /** calculate phase, gain */
    for (var i = 0; i < numSample; i++) {
      for (var j = 0; j < numPoint; j++) {
        txPhase[i][j] *= (1.8 / 4294967296);
        txPhase[i][j] /= 0.01;
      }
    }

    for (var i = 0; i < txGain.row; i++) {
      for (var j = 0; j < txGain.column; j++) {
        txGain[i][j] *= (1.8 / 4294967296);
        txGain[i][j] = -30 + (txGain[i][j] / 0.03);
        txGain[i][j] = pow(10, (txGain[i][j] / 20)).toDouble();
      }
    }

    /** Convert Z */
    var txZReal = Array2d.fixed(numSample, numPoint);
    var txZImag = Array2d.fixed(numSample, numPoint);
    double rTx = 5;

    for (var i = 0; i < numSample; i++) {
      for (var j = 0; j < numPoint; j++) {
        txZReal[i][j] =
            (txGain[i][j] * cos(pi - (txPhase[i][j] * pi / 180)) - 1) * rTx;
        txZImag[i][j] =
            (txGain[i][j] * sin(pi - (txPhase[i][j] * pi / 180)) - 0) * rTx;
      }
    }

    /** Average 2D */
    txZRealMean = array2dMean(txZReal);
    txZImagMean = array2dMean(txZImag);

    /** Init Self */
    this.fileName = fileName;
    this.startFreq = startFreq;
    this.endFreq = endFreq;
    this.numPoint = numPoint;
    txZRealMean = txZRealMean.copy();
    txZImagMean = txZImagMean.copy();
  }
}

class TxRxSimulator {
  String fileName = "";
  double startFreq = 0.0;
  double endFreq = 0.0;
  int numPoint = 0;
  Array2d txZReal = Array2d.empty();
  Array2d txZImag = Array2d.empty();
  int curSampleIdx = 0;
  void initFromFile(String fileName) {
    /** File Read */
    List<String> txtFile = File(fileName).readAsLinesSync();

    /** Get Info Header */
    var infoList = txtFile[0].split(" ").map(double.parse).toList();
    var startFreq = infoList[0];
    var endFreq = infoList[1];
    var numPoint = infoList[2].toInt();
    var numSample = txtFile.length - 1;

    /** parse time */
    // var txDataTimeStamp =
    //   List<DateTime>.empty(growable: true); // todo:fixed len list
    // for (var i = 1; i < txtFile.length; i++) {
    //   String tmpDt = txtFile[i].substring(0, 26);
    //   txDataTimeStamp.add(DateTime.parse(tmpDt));
    // }

    /** Parse phase,gain */
    var txPhase = Array2d.fixed(numSample, numPoint);
    var txGain = Array2d.fixed(numSample, numPoint);
    for (var i = 1; i < txtFile.length; i++) {
      String tmpData = txtFile[i].substring(27); // 27은 앞에 DateTime 처리용인듯 하다.
      List<double> dataList = tmpData.split(" ").map(double.parse).toList();

      int nPoint = (dataList.length ~/ 2);
      var tmpPhase = Array.fixed(numPoint);
      var tmpGain = Array.fixed(numPoint);
      for (var j = 0; j < nPoint; j++) {
        tmpPhase[j] = dataList[2 * j + 0];
        tmpGain[j] = dataList[2 * j + 1];
      }
      txPhase[i - 1] = tmpPhase.copy();
      txGain[i - 1] = tmpGain.copy();
    }

    /** calculate phase, gain */
    for (var i = 0; i < numSample; i++) {
      for (var j = 0; j < numPoint; j++) {
        txPhase[i][j] *= (1.8 / 4294967296);
        txPhase[i][j] /= 0.01;
      }
    }

    for (var i = 0; i < txGain.row; i++) {
      for (var j = 0; j < txGain.column; j++) {
        txGain[i][j] *= (1.8 / 4294967296);
        txGain[i][j] = -30 + (txGain[i][j] / 0.03);
        txGain[i][j] = pow(10, (txGain[i][j] / 20)).toDouble();
      }
    }

    /** Convert Z */
    var txZReal = Array2d.fixed(numSample, numPoint);
    var txZImag = Array2d.fixed(numSample, numPoint);
    double rTx = 5;

    for (var i = 0; i < numSample; i++) {
      for (var j = 0; j < numPoint; j++) {
        txZReal[i][j] =
            (txGain[i][j] * cos(pi - (txPhase[i][j] * pi / 180)) - 1) * rTx;
        txZImag[i][j] =
            (txGain[i][j] * sin(pi - (txPhase[i][j] * pi / 180)) - 0) * rTx;
      }
    }

    /** Init Self */
    this.fileName = fileName;
    this.startFreq = startFreq;
    this.endFreq = endFreq;
    this.numPoint = numPoint;
    this.txZReal = txZReal.copy();
    this.txZImag = txZImag.copy();
  }

  (Array, Array) getOneSample() {
    /** Return (ZReal, ZImag) */
    if (numPoint == 0) return (Array.empty(), Array.empty());

    int curIdx = curSampleIdx;
    int nextIdx = curIdx + 1;
    if (nextIdx >= txZReal.row) {
      nextIdx = 0;
    }

    curSampleIdx = nextIdx;
    return (txZReal[curIdx], txZImag[curIdx]);
  }
}

void main(List<String> arguments) {
  /** File Selected */
  var a = TxBaseLine();
  a.initFromFile("test/LedOn(baseline).txt");
  a.initFilter(5, 1.5);
  a.initMatResample((a.numPoint - 1) * 20 + 1);

  /**  */
  var d = TxRxSimulator();
  d.initFromFile("test/LedOff.txt");

  for (var i = 0; i < 1000; i++) {
    var (txrxZReal, txrxZImag) = d.getOneSample();
    // var txrxZReal = Array(zRealData);
    // var txrxZImag = Array(zImagData);

    Array zReal = txrxZReal - a.txZRealMean;
    Array zImag = txrxZImag - a.txZImagMean;

    Array zrealFilt = a.convFilter(zReal);
    Array zrealInterp = a.matResample(zrealFilt);

    double resFreq = a.getPeakFrequencyFromResample(zrealInterp);
    print(resFreq);
  }

  // Stopwatch stopwatch = new Stopwatch()..start();
  // for (var i = 0; i < 1000; i++) {
  //   var (txrxZReal, txrxZImag) = d.getOneSample();
  //   Array zReal = txrxZReal - a.txZRealMean;
  //   Array zImag = txrxZImag - a.txZImagMean;

  //   var zReal_filt = a.convFilter(zReal);
  //   // print(zReal_filt);

  //   var zReal_interp = a.matResample(zReal_filt);
  //   // print(zReal_interp);

  //   var resFreq = a.getPeakFrequencyFromResample(zReal_interp);
  //   // print(resFreq);
  // }
  // var elsapTime = stopwatch.elapsed;

  // print('doSomething() executed in ${elsapTime}');
  // print('doSomething() executed in ${elsapTime.inMicroseconds ~/ 1000}');

  // /** Draw Lines to SVG */
  // var line1 = PlotGeneral(
  //     ay: zReal, plotGeneralType: PlotGeneralType.Line, stroke: Color.blue);
  // var line2 = PlotGeneral(
  //     ay: zReal_filt,
  //     plotGeneralType: PlotGeneralType.Line,
  //     stroke: Color.orange);

  // // var legend1 = LegendItem("txZRealMean");
  // // var legend2 = LegendItem("txZImagMean");

  // var plotExample = canvasGeneral(
  //   ax: linspace(a.startFreq, a.endFreq, num: a.numPoint, endpoint: true),
  //   lines: [line1, line2],
  //   title: 'Example plot',
  //   // legend: Legend([legend1, legend2], LegendPosition.topRight)
  // );
  // // plotExample.toXML()
  // // print(plotExample.toXML());
  // saveSvg(plotExample, "test/test2.svg");

  // /** Draw Lines to SVG */
  // var line11 = PlotGeneral(
  //     ay: zReal_interp,
  //     plotGeneralType: PlotGeneralType.Line,
  //     stroke: Color.blue);

  // var plotExample2 = canvasGeneral(
  //   ax: linspace(a.startFreq, a.endFreq,
  //       num: (a.numPoint - 1) * 100 + 1, endpoint: true),
  //   lines: [line11],
  //   title: 'Example plot',
  //   // legend: Legend([legend1, legend2], LegendPosition.topRight)
  // );
  // // plotExample.toXML()
  // // print(plotExample.toXML());
  // saveSvg(plotExample2, "test/test21.svg");
}

Future<void> saveSvg(SvgCanvas svgCanvas, String fileName) async {
  const extension = '.svg';
  if (!fileName.toLowerCase().endsWith(extension)) {
    fileName += extension;
  }
  await writeTxt(svgCanvas.toXML(), fileName);
}
