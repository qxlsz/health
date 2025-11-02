import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:health_app/src/models/health_data.dart';

/// Widget for displaying sleep stages as a pie chart
class SleepStagesPieChart extends StatelessWidget {
  final SleepSession session;

  const SleepStagesPieChart({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final remPercent = session.getStagePercentage('REM');
    final deepPercent = session.getStagePercentage('DEEP');
    final lightPercent = session.getStagePercentage('LIGHT');
    final awakePercent = session.getStagePercentage('AWAKE');

    final data = [
      _SleepStageData('REM', remPercent, Colors.purple),
      _SleepStageData('Deep', deepPercent, Colors.blue),
      _SleepStageData('Light', lightPercent, Colors.lightBlue),
      _SleepStageData('Awake', awakePercent, Colors.grey),
    ].where((d) => d.value > 0).toList();

    return charts.PieChart(
      [
        charts.Series<_SleepStageData, String>(
          id: 'Sleep Stages',
          domainFn: (data, _) => data.label,
          measureFn: (data, _) => data.value,
          colorFn: (data, _) => charts.ColorUtil.fromDartColor(data.color),
          data: data,
          labelAccessorFn: (data, _) => '${data.label}\n${data.value.toStringAsFixed(1)}%',
        ),
      ],
      animate: true,
      defaultRenderer: charts.ArcRendererConfig(
        arcWidth: 60,
        arcRendererDecorators: [
          charts.ArcLabelDecorator(
            labelPosition: charts.ArcLabelPosition.auto,
          ),
        ],
      ),
    );
  }
}

class _SleepStageData {
  final String label;
  final double value;
  final Color color;

  _SleepStageData(this.label, this.value, this.color);
}

