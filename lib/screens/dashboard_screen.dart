import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mock/mock_state.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    return Container(
      color: AppTheme.obsidianBlack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Command Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Command Dashboard Overview',
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.titaniumWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time automated sector surveillance and border telemetry',
                      style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.charcoalSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, size: 14, color: AppTheme.tacticalAmber),
                      const SizedBox(width: 8),
                      Text(
                        'DEFCON 4 • NORMAL VIGILANCE',
                        style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Interactive KPI Summary Cards
            Row(
              children: [
                _InteractiveKpiCard(title: 'Active Cameras', value: state.cameras.length.toString(), icon: Icons.videocam_outlined, color: AppTheme.titaniumWhite),
                _InteractiveKpiCard(title: 'Online Feeds', value: state.cameras.where((c) => c.status == CameraStatus.online).length.toString(), icon: Icons.check_circle_outline, color: AppTheme.radarGreen),
                _InteractiveKpiCard(title: 'Offline Feeds', value: state.cameras.where((c) => c.status == CameraStatus.offline).length.toString(), icon: Icons.error_outline, color: AppTheme.tacticalAmber),
                _InteractiveKpiCard(title: 'Active Alerts', value: state.alerts.where((a) => a.status == AlertStatus.active).length.toString(), icon: Icons.warning_amber_rounded, color: AppTheme.alertRed),
                _InteractiveKpiCard(title: 'Patrol Sectors', value: state.zones.length.toString(), icon: Icons.map_outlined, color: AppTheme.titaniumWhite, isLast: true),
              ],
            ),
            const SizedBox(height: 28),

            // Main Content: Feeds + Alerts & Chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Camera Nodes
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Priority Surveillance Feeds', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                          Text('Showing 6 Active Optical / Thermal Feeds', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedSilver)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 16 / 10,
                            ),
                            itemCount: state.cameras.length > 6 ? 6 : state.cameras.length,
                            itemBuilder: (context, index) {
                              return _InteractiveCameraFeed(camera: state.cameras[index]);
                            },
                          );
                        }
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Alerts & Chart
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Live Threat Log', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.alertRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.alertRed.withOpacity(0.5)),
                            ),
                            child: Text(
                              '${state.alerts.where((a) => a.status == AlertStatus.active).length} ACTIVE',
                              style: GoogleFonts.inter(color: AppTheme.alertRed, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...state.alerts.take(3).map((a) => _InteractiveAlertCard(alert: a)),
                      const SizedBox(height: 24),
                      Text('Intrusion Frequency (24H)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                      const SizedBox(height: 14),
                      _buildChartCard(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      height: 195,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.subtleBorder, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 9),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 1),
                FlSpot(1, 1.8),
                FlSpot(2, 1.4),
                FlSpot(3, 3.8),
                FlSpot(4, 2.2),
                FlSpot(5, 2.5),
                FlSpot(6, 1.9),
                FlSpot(7, 2.9),
                FlSpot(8, 2.4),
              ],
              isCurved: true,
              color: AppTheme.tacticalAmber,
              barWidth: 2.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.tacticalAmber.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLast;

  const _InteractiveKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  @override
  State<_InteractiveKpiCard> createState() => _InteractiveKpiCardState();
}

class _InteractiveKpiCardState extends State<_InteractiveKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(right: widget.isLast ? 0 : 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.charcoalElevated : AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? AppTheme.tacticalAmber.withOpacity(0.6) : AppTheme.hairlineBorder,
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.tacticalAmber.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianBlack,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _isHovered ? widget.color.withOpacity(0.5) : AppTheme.hairlineBorder),
                ),
                child: Icon(widget.icon, size: 20, color: widget.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.titaniumWhite),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveCameraFeed extends StatefulWidget {
  final Camera camera;

  const _InteractiveCameraFeed({required this.camera});

  @override
  State<_InteractiveCameraFeed> createState() => _InteractiveCameraFeedState();
}

class _InteractiveCameraFeedState extends State<_InteractiveCameraFeed> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isOnline = widget.camera.status == CameraStatus.online;
    bool hasThreat = widget.camera.currentDetection != 'No Threat' && widget.camera.currentDetection != 'Offline';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasThreat
                  ? AppTheme.alertRed
                  : (_isHovered ? AppTheme.tacticalAmber : AppTheme.hairlineBorder),
              width: hasThreat ? 1.8 : 1.0,
            ),
            boxShadow: [
              if (hasThreat)
                BoxShadow(
                  color: AppTheme.alertRed.withOpacity(0.2),
                  blurRadius: 10,
                )
              else if (_isHovered)
                BoxShadow(
                  color: AppTheme.tacticalAmber.withOpacity(0.12),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  Icons.videocam_outlined,
                  size: 40,
                  color: isOnline ? AppTheme.titaniumWhite.withOpacity(0.2) : AppTheme.titaniumWhite.withOpacity(0.08),
                ),
              ),
              // Top Left Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasThreat ? AppTheme.alertRed : (isOnline ? AppTheme.radarGreen : AppTheme.obsidianBlack),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOnline ? (hasThreat ? 'BREACH ALERT' : 'LIVE') : 'OFFLINE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.titaniumWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Top Right ID
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Text(
                    widget.camera.id,
                    style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Bottom Details
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack.withOpacity(0.92),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7)),
                    border: const Border(top: BorderSide(color: AppTheme.hairlineBorder)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.camera.location,
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.titaniumWhite, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasThreat ? AppTheme.alertRed : (isOnline ? AppTheme.radarGreen : Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.camera.currentDetection,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: hasThreat ? AppTheme.alertRed : AppTheme.mutedSilver,
                                fontWeight: hasThreat ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveAlertCard extends StatefulWidget {
  final Alert alert;

  const _InteractiveAlertCard({required this.alert});

  @override
  State<_InteractiveAlertCard> createState() => _InteractiveAlertCardState();
}

class _InteractiveAlertCardState extends State<_InteractiveAlertCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isCritical = widget.alert.severity == AlertSeverity.critical;
    Color accentColor = isCritical ? AppTheme.alertRed : AppTheme.tacticalAmber;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.charcoalElevated : AppTheme.charcoalSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isHovered ? accentColor : (isCritical ? accentColor.withOpacity(0.5) : AppTheme.hairlineBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.obsidianBlack,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentColor.withOpacity(0.5)),
              ),
              child: Icon(Icons.warning_amber_rounded, color: accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.alert.severity.toString().split('.').last.toUpperCase()} ALERT',
                        style: GoogleFonts.inter(color: accentColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      Text('RECENT', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.alert.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.titaniumWhite),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.alert.cameraId} • ${widget.alert.location}',
                    style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
