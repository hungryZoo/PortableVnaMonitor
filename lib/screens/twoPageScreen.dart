import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pvm_col/data.dart';

class twoGraphScreen extends StatefulWidget {
  const twoGraphScreen({super.key});

  @override
  twoGraphScreenState createState() => twoGraphScreenState();
}

class twoGraphScreenState extends State<twoGraphScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                title: AxisTitle(
                  text: 'freuquency(MHz)',
                  textStyle: TextStyle(fontSize: baseSize * 1.2),
                ),
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
          Expanded(
            flex: 1,
            child: SfCartesianChart(
                primaryXAxis: NumericAxis(
                  title: AxisTitle(
                    text: 'freuquency(MHz)',
                    textStyle: TextStyle(fontSize: baseSize * 1.2),
                  ),
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
                    color: Colors.red,
                    onRendererCreated: (controller) =>
                        gainGraphController = controller,
                    dataSource: gainGraphData,
                    xValueMapper: (GraphData data, _) => data.x,
                    yValueMapper: (GraphData data, _) => data.y,
                  )
                ]),
          )
        ],
      ),
    );
  }
}
