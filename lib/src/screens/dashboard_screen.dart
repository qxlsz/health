import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/src/providers/auth_provider.dart';
import 'package:health_app/src/providers/health_provider.dart';
import 'package:health_app/src/providers/analysis_provider.dart';
import 'package:health_app/src/widgets/sleep_stages_pie_chart.dart';
import 'package:health_app/src/widgets/sleep_trends_chart.dart';
import 'package:health_app/src/routing/app_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final sleepSummary = ref.watch(sleepSummaryProvider);
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sleepSummaryProvider);
          ref.invalidate(devicesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.value?.email ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sleep Summary Cards
              sleepSummary.when(
                data: (summary) {
                  if (summary.totalSessions == 0) {
                    return _buildEmptyState(context);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Efficiency',
                              value: '${summary.averageEfficiency.toStringAsFixed(1)}%',
                              icon: Icons.bedtime,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Avg Duration',
                              value: _formatDuration(summary.averageDuration),
                              icon: Icons.access_time,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'REM Sleep',
                              value: '${summary.averageRemPercentage.toStringAsFixed(1)}%',
                              icon: Icons.visibility,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Deep Sleep',
                              value: '${summary.averageDeepPercentage.toStringAsFixed(1)}%',
                              icon: Icons.nights_stay,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sleep Trends Chart
                      Text(
                        'Sleep Trends (Last 7 Days)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 250,
                            child: SleepTrendsChart(
                              sessions: summary.recentSessions,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sleep Analysis & Recommendations
                      _AnalysisSection(session: summary.recentSessions.isNotEmpty ? summary.recentSessions.first : null),

                      const SizedBox(height: 24),

                      // Latest Sleep Session Details
                      if (summary.recentSessions.isNotEmpty) ...[
                        Text(
                          'Latest Sleep Session',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _LatestSleepCard(
                          session: summary.recentSessions.first,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  color: Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading sleep data',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Connected Devices
              devices.when(
                data: (deviceList) {
                  if (deviceList.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.devices, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'No devices connected',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect a device to start tracking',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push('/onboarding');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Connect Device'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected Devices',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...deviceList.map((device) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _getDeviceIcon(device.type),
                              title: Text(device.displayName),
                              subtitle: device.lastSyncAt != null
                                  ? Text(
                                      'Last sync: ${DateFormat('MMM d, y').format(device.lastSyncAt!)}',
                                    )
                                  : const Text('Never synced'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          )),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.bedtime_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No sleep data yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect a device and start tracking your sleep',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/onboarding');
              },
              icon: const Icon(Icons.add),
              label: const Text('Connect Device'),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getDeviceIcon(String type) {
    switch (type) {
      case 'apple':
        return const Icon(Icons.watch, color: Colors.grey);
      case 'android':
        return const Icon(Icons.watch, color: Colors.green);
      case 'whoop':
        return const Icon(Icons.fitness_center, color: Colors.orange);
      default:
        return const Icon(Icons.device_unknown);
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestSleepCard extends StatelessWidget {
  final dynamic session; // SleepSession

  const _LatestSleepCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final efficiency = session.calculateEfficiency();
    final duration = session.totalDuration;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, y').format(session.startTime),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  label: Text('${efficiency.toStringAsFixed(0)}%'),
                  backgroundColor: efficiency >= 85
                      ? Colors.green.withOpacity(0.2)
                      : efficiency >= 70
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Duration',
                    value: '${duration ~/ 60}h ${duration % 60}m',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'REM',
                    value: '${session.getStagePercentage('REM').toStringAsFixed(1)}%',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Deep',
                    value: '${session.getStagePercentage('DEEP').toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: SleepStagesPieChart(session: session),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}

class _AnalysisSection extends ConsumerWidget {
  final dynamic session;

  const _AnalysisSection({this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session == null) {
      return const SizedBox.shrink();
    }

    final analysisAsync = ref.watch(analyzeSessionProvider(session));
    final trendsAsync = ref.watch(analyzeTrendsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep Analysis',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        analysisAsync.when(
          data: (analysis) {
            final sleepScore = analysis['sleep_score'] as num? ?? 0.0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sleep Score',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Chip(
                          label: Text('${sleepScore.toStringAsFixed(0)}/100'),
                          backgroundColor: _getScoreColor(sleepScore).withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: sleepScore / 100,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(sleepScore)),
                    ),
                    if (analysis['note'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        analysis['note'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        trendsAsync.when(
          data: (trends) {
            final recommendations = trends['recommendations'] as List? ?? [];
            if (recommendations.isEmpty) {
              return const SizedBox.shrink();
            }
            return Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Recommendations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
