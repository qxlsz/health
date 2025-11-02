import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:health_app/src/models/health_data.dart';
import 'package:intl/intl.dart';

/// Widget for displaying sleep trends over time
class SleepTrendsChart extends StatelessWidget {
  final List<SleepSession> sessions;

  const SleepTrendsChart({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No sleep data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Sort by date (oldest first)
    final sortedSessions = List<SleepSession>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final efficiencyData = sortedSessions
        .map((s) => _SleepTrendData(
              date: s.startTime,
              efficiency: s.calculateEfficiency(),
              duration: s.totalDuration,
            ))
        .toList();

    return charts.TimeSeriesChart(
      [
        charts.Series<_SleepTrendData, DateTime>(
          id: 'Sleep Efficiency',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (data, _) => data.date,
          measureFn: (data, _) => data.efficiency,
          data: efficiencyData,
          labelAccessorFn: (data, _) =>
              '${DateFormat('MMM d').format(data.date)}\n${data.efficiency.toStringAsFixed(0)}%',
        ),
        charts.Series<_SleepTrendData, DateTime>(
          id: 'Duration',
          colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
          domainFn: (data, _) => data.date,
          measureFn: (data, _) => data.duration / 60.0, // Convert to hours
          data: efficiencyData,
          yAxisId: 'duration',
        ),
      ],
      animate: true,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(
          zeroBound: false,
          dataIsInWholeNumbers: false,
        ),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
            fontSize: 12,
            color: charts.MaterialPalette.gray.shadeDefault,
          ),
        ),
      ),
      secondaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(
          zeroBound: false,
          dataIsInWholeNumbers: false,
        ),
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
            fontSize: 12,
            color: charts.MaterialPalette.gray.shadeDefault,
          ),
        ),
      ),
      behaviors: [
        charts.SeriesLegend(),
        charts.SliderLegend(
          position: charts.BehaviorPosition.bottom,
        ),
      ],
    );
  }
}

class _SleepTrendData {
  final DateTime date;
  final double efficiency;
  final int duration;

  _SleepTrendData({
    required this.date,
    required this.efficiency,
    required this.duration,
  });
}

