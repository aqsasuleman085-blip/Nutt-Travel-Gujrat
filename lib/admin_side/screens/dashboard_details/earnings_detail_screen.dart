import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/dashboard_provider.dart';

/// Detail screen shown when the admin taps the "Total Earnings" dashboard
/// card. Shows a bigger revenue trend chart across the last 7 days.
class EarningsDetailScreen extends StatelessWidget {
  const EarningsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final days = dashboardProvider.last7Days;
    final maxEarning = days.isEmpty
        ? 1.0
        : days
            .map((d) => d.earnings)
            .fold(0.0, (a, b) => a > b ? a : b)
            .clamp(1, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Overview'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earnings',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${dashboardProvider.totalEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const Text(
                  'From all approved bookings',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'LAST 7 DAYS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxEarning.toDouble() * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxEarning / 4).clamp(
                    1,
                    double.infinity,
                  ),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final day = days[index].day;
                        const labels = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[day.weekday - 1],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          'Rs ${spot.y.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      days.length,
                      (i) => FlSpot(i.toDouble(), days[i].earnings),
                    ),
                    isCurved: true,
                    color: AppConstants.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstants.primaryColor.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'DAILY BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          ...days.reversed.map((d) {
            const labels = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${labels[d.day.weekday - 1]}, ${d.day.day}/${d.day.month}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Rs ${d.earnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
