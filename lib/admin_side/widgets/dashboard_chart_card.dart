import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Which mini-chart style to draw on the right side of a dashboard card.
enum MiniChartType { bar, line, donut }

/// A dashboard metric card with a small chart fixed to its right side.
/// Tapping the whole card navigates to [onTap], which should push the
/// relevant detail screen (e.g. a user list, or a bigger chart).
class DashboardChartCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final MiniChartType chartType;

  /// Values used to draw the mini-chart. For bar/line: one value per bar
  /// (e.g. 7 days). For donut: exactly 2 values (e.g. [active, inactive]).
  final List<double> chartValues;

  /// Colors for donut segments. Ignored for bar/line (uses iconColor).
  final List<Color>? donutColors;

  final VoidCallback onTap;

  const DashboardChartCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.chartType,
    required this.chartValues,
    required this.onTap,
    this.donutColors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Fixed-size mini-chart on the card, right-aligned area.
              SizedBox(
                height: 34,
                width: double.infinity,
                child: _buildMiniChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    switch (chartType) {
      case MiniChartType.bar:
        return _buildMiniBar();
      case MiniChartType.line:
        return _buildMiniLine();
      case MiniChartType.donut:
        return _buildMiniDonut();
    }
  }

  Widget _buildMiniBar() {
    final maxVal = chartValues.isEmpty
        ? 1.0
        : chartValues.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal.toDouble(),
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(enabled: false),
        barGroups: List.generate(chartValues.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: chartValues[i],
                color: iconColor,
                width: 6,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMiniLine() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              chartValues.length,
              (i) => FlSpot(i.toDouble(), chartValues[i]),
            ),
            isCurved: true,
            color: iconColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: iconColor.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDonut() {
    final colors = donutColors ?? [iconColor, Colors.grey.shade300];
    final total = chartValues.fold(0.0, (a, b) => a + b);

    if (total == 0) {
      return Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 4),
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 8,
        sections: List.generate(chartValues.length, (i) {
          return PieChartSectionData(
            value: chartValues[i],
            color: i < colors.length ? colors[i] : Colors.grey,
            showTitle: false,
            radius: 10,
          );
        }),
      ),
    );
  }
}
