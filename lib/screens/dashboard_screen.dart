import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mock/mock_state.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../theme/app_theme.dart';
import '../widgets/live_camera_feed.dart';
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
                // Real-time DEFCON Badge based on live webcam telemetry
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.defconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: state.defconColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: state.defconColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, size: 14, color: state.defconColor),
                      const SizedBox(width: 8),
                      Text(
                        state.defconStatus,
                        style: GoogleFonts.inter(color: state.defconColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Interactive KPI Summary Cards - Real-time Connected
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _InteractiveKpiCard(
                    title: 'Physical Inputs',
                    value: '1 Active',
                    icon: Icons.videocam,
                    color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                  ),
                  _InteractiveKpiCard(
                    title: 'CAM-01 Feed State',
                    value: state.isCameraOn ? '${state.cam1Fps.toStringAsFixed(0)} FPS' : 'STANDBY',
                    icon: state.isCameraOn ? Icons.check_circle_outline : Icons.power_settings_new,
                    color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                  ),
                  _InteractiveKpiCard(
                    title: 'Vacant Channels',
                    value: '${state.cameras.where((c) => c.isEmptySlot).length} Empty',
                    icon: Icons.sensors_off_outlined,
                    color: AppTheme.mutedSilver,
                  ),
                  _InteractiveKpiCard(
                    title: 'Active Alerts',
                    value: state.alerts.length.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: state.alerts.isNotEmpty ? AppTheme.alertRed : AppTheme.tacticalAmber,
                  ),
                  _InteractiveKpiCard(
                    title: 'AI Engine Mode',
                    value: state.activeAiMode.toUpperCase(),
                    icon: Icons.psychology_outlined,
                    color: AppTheme.tacticalAmber,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Camera Hardware ON/OFF Power Controller
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.charcoalSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.isCameraOn ? AppTheme.radarGreen.withValues(alpha: 0.4) : AppTheme.alertRed.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                      boxShadow: [
                        BoxShadow(
                          color: (state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed).withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'PRIMARY INPUT: CAM-01 (LAPTOP WEBCAM)',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppTheme.titaniumWhite,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: state.isCameraOn ? AppTheme.radarGreen.withValues(alpha: 0.15) : AppTheme.alertRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                                ),
                              ),
                              child: Text(
                                state.isCameraOn ? 'STREAMING ACTIVE' : 'MUTED / OFF',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          state.isCameraOn
                              ? 'Live hardware feed transmitting at ${state.cam1Fps.toStringAsFixed(1)} FPS • ${state.activeAiMode.toUpperCase()} AI active • Sector 01'
                              : 'Camera sensor powered off • In privacy standby • Click button to re-activate hardware',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.mutedSilver,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      state.toggleCameraPower();
                    },
                    icon: Icon(
                      state.isCameraOn ? Icons.power_settings_new : Icons.videocam,
                      size: 16,
                      color: state.isCameraOn ? AppTheme.alertRed : AppTheme.obsidianBlack,
                    ),
                    label: Text(
                      state.isCameraOn ? 'POWER OFF CAMERA' : 'ACTIVATE CAMERA',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: state.isCameraOn ? AppTheme.alertRed : AppTheme.obsidianBlack,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isCameraOn
                          ? AppTheme.alertRed.withValues(alpha: 0.15)
                          : AppTheme.radarGreen,
                      side: BorderSide(
                        color: state.isCameraOn ? AppTheme.alertRed : AppTheme.radarGreen,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                          Text('Surveillance Channels Grid', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                          Text('1 Active Hardware Input • 5 Vacant Slots', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedSilver)),
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
                              childAspectRatio: 16 / 9.5,
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
                              color: AppTheme.alertRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '${state.alerts.where((a) => a.status == AlertStatus.active).length} ACTIVE',
                              style: GoogleFonts.inter(color: AppTheme.alertRed, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (state.alerts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.charcoalSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.hairlineBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.obsidianBlack,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(Icons.verified_user_outlined, color: AppTheme.radarGreen, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SECTOR 01: PERIMETER CLEAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.titaniumWhite)),
                                    const SizedBox(height: 2),
                                    Text('No active threats or unauthorized incursions detected on CAM-01 stream.', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedSilver)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...state.alerts.take(3).map((a) => _InteractiveAlertCard(alert: a)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Live Target Detection Activity', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.radarGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'REALTIME STREAM',
                              style: GoogleFonts.inter(color: AppTheme.radarGreen, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildChartCard(state),
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

  Widget _buildChartCard(MockState state) {
    final hasBreach = state.intrusionDetected;
    final primaryColor = hasBreach ? AppTheme.alertRed : AppTheme.tacticalAmber;
    final spots = state.detectionHistory;
    final totalTargets = (state.cam1Counts['person'] ?? 0) + (state.cam1Counts['vehicle'] ?? 0) + (state.cam1Counts['animal'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasBreach ? AppTheme.alertRed.withValues(alpha: 0.5) : AppTheme.hairlineBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CAM-01 TELEMETRY TIMELINE',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedSilver, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  hasBreach ? 'BREACH FLAGGED' : '$totalTargets TARGETS ACTIVE',
                  style: GoogleFonts.inter(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 135,
            child: Builder(
              builder: (context) {
                final maxSpotY = spots.map((s) => s.y).fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);
                final dynamicMaxY = (maxSpotY + 2.0).clamp(5.0, 50.0);

                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: dynamicMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.subtleBorder, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: dynamicMaxY > 10 ? 5 : 1,
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
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: primaryColor,
                        barWidth: 2.2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Real-time telemetry breakdown strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.obsidianBlack,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.hairlineBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniTelemetryStat('Persons', '${state.cam1Counts['person'] ?? 0}'),
                _buildMiniTelemetryStat('Vehicles', '${state.cam1Counts['vehicle'] ?? 0}'),
                _buildMiniTelemetryStat('Animals', '${state.cam1Counts['animal'] ?? 0}'),
                _buildMiniTelemetryStat('Faces', '${state.cam1Counts['face'] ?? 0}'),
                _buildMiniTelemetryStat('Stream', state.isCameraOn ? '${state.cam1Fps.toStringAsFixed(0)} FPS' : 'OFF'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMiniTelemetryStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 9)),
        const SizedBox(height: 1),
        Text(value, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
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
    return Container(
      width: 220,
      margin: EdgeInsets.only(right: widget.isLast ? 0 : 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.charcoalElevated : AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? AppTheme.tacticalAmber.withValues(alpha: 0.6) : AppTheme.hairlineBorder,
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.tacticalAmber.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.color.withValues(alpha: 0.4)),
                ),
                child: Icon(widget.icon, size: 20, color: widget.color),
              ),
              const SizedBox(width: 12),
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
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.titaniumWhite),
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
    bool hasThreat = widget.camera.currentDetection != 'No Threat' &&
        widget.camera.currentDetection != 'Offline (Start backend_server.py)' &&
        widget.camera.currentDetection != 'Camera Hardware Powered Off' &&
        widget.camera.currentDetection != 'Sensor Inactive (Camera Off)';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppTheme.charcoalSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasThreat
                ? AppTheme.alertRed
                : (_isHovered ? AppTheme.tacticalAmber : AppTheme.hairlineBorder),
            width: hasThreat ? 1.8 : 1.0,
          ),
          boxShadow: [
            if (hasThreat)
              BoxShadow(
                color: AppTheme.alertRed.withValues(alpha: 0.2),
                blurRadius: 10,
              )
            else if (_isHovered)
              BoxShadow(
                color: AppTheme.tacticalAmber.withValues(alpha: 0.12),
                blurRadius: 12,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              LiveCameraFeed(camera: widget.camera),

              // Top-left floating camera ID tag
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Text(
                    '${widget.camera.id} • ${widget.camera.zone}',
                    style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              // Top-right status pill
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isOnline ? AppTheme.radarGreen.withValues(alpha: 0.4) : AppTheme.alertRed.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppTheme.radarGreen : AppTheme.alertRed,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? 'ONLINE' : 'STANDBY',
                        style: GoogleFonts.inter(
                          color: isOnline ? AppTheme.radarGreen : AppTheme.alertRed,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom floating details bar
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasThreat ? AppTheme.alertRed.withValues(alpha: 0.6) : AppTheme.hairlineBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.camera.location,
                          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.titaniumWhite, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.camera.currentDetection,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: hasThreat ? AppTheme.alertRed : AppTheme.mutedSilver,
                          fontWeight: hasThreat ? FontWeight.bold : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
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
            color: _isHovered ? accentColor : (isCritical ? accentColor.withValues(alpha: 0.5) : AppTheme.hairlineBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.obsidianBlack,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
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
