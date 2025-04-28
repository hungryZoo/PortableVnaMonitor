import 'package:flutter/material.dart';
import 'package:pvm_col/data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Onegraphscreen extends StatefulWidget {
  const Onegraphscreen({super.key});

  @override
  OnegraphscreenState createState() => OnegraphscreenState();
}

class OnegraphscreenState extends State<Onegraphscreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: SfCartesianChart(
        series: <LineSeries<MainGraphData, dynamic>>[
          LineSeries(
            onRendererCreated: (controller) => mainGraphController = controller,
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
    );
  }

  void update() {
    setState(() {});
  }
}
