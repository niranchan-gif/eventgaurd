import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = '7 Days';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkOlive,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Surveillance Intelligence & Analytics', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.cream)),
                    const SizedBox(height: 4),
                    Text('AI Detection frequency and automated threat trend reports', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.deepGreen,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppTheme.deepGreen,
                      value: _timeRange,
                      style: GoogleFonts.inter(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 13),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.orange),
                      items: ['Today', '7 Days', '30 Days'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _timeRange = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildChartCard(
                    'Intrusions & Breach Alerts Trend',
                    LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.borderSubtle, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                                if (val.toInt() >= 0 && val.toInt() < days.length) {
                                  return Text(days[val.toInt()], style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10));
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10)),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [FlSpot(0, 1), FlSpot(1, 4), FlSpot(2, 2.5), FlSpot(3, 6), FlSpot(4, 3)],
                            isCurved: true,
                            color: AppTheme.orange,
                            barWidth: 3,
                            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(radius: 4, color: AppTheme.orange, strokeColor: AppTheme.darkOlive, strokeWidth: 2);
                            }),
                            belowBarData: BarAreaData(show: true, color: AppTheme.orange.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildChartCard(
                    'Threat Classification Breakdown',
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: AppTheme.orange,
                            value: 45,
                            title: 'Human (45%)',
                            titleStyle: GoogleFonts.inter(color: AppTheme.darkOlive, fontWeight: FontWeight.bold, fontSize: 11),
                            radius: 50,
                          ),
                          PieChartSectionData(
                            color: AppTheme.cream,
                            value: 30,
                            title: 'Vehicle (30%)',
                            titleStyle: GoogleFonts.inter(color: AppTheme.darkOlive, fontWeight: FontWeight.bold, fontSize: 11),
                            radius: 46,
                          ),
                          PieChartSectionData(
                            color: AppTheme.safe,
                            value: 25,
                            title: 'Wildlife (25%)',
                            titleStyle: GoogleFonts.inter(color: AppTheme.darkOlive, fontWeight: FontWeight.bold, fontSize: 11),
                            radius: 44,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildChartCard(
                    'Node Cluster Hardware Uptime (%)',
                    BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.borderSubtle, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                return Text('Node 0${val.toInt() + 1}', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (val, meta) => Text('${val.toInt()}%', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 9)),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 98, color: AppTheme.safe, width: 22, borderRadius: BorderRadius.circular(4))]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 99, color: AppTheme.safe, width: 22, borderRadius: BorderRadius.circular(4))]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 94, color: AppTheme.cream, width: 22, borderRadius: BorderRadius.circular(4))]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 99, color: AppTheme.safe, width: 22, borderRadius: BorderRadius.circular(4))]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 88, color: AppTheme.orange, width: 22, borderRadius: BorderRadius.circular(4))]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      height: 290,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.deepGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cream)),
          const SizedBox(height: 18),
          Expanded(child: chart),
        ],
      ),
    );
  }
}
