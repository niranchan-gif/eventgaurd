import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../mock/mock_state.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../widgets/live_camera_feed.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = 'Live Optical Stream (Real-Time)';
  String _selectedCameraId = 'CAM-001';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final activeCam = state.cameras.firstWhere(
      (c) => c.id == _selectedCameraId,
      orElse: () => state.cameras.first,
    );

    return Container(
      color: AppTheme.obsidianBlack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Command & Live Stream Header Bar
            _buildHeader(state),
            const SizedBox(height: 20),

            // Real-Time Optical Telemetry Strip
            _buildTelemetryStrip(state),
            const SizedBox(height: 24),

            // Row 1: Live Video Feed Player + Live Target Telemetry Waveform
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Camera Feed Monitor
                Expanded(
                  flex: 5,
                  child: _buildLiveCameraCard(state, activeCam),
                ),
                const SizedBox(width: 20),

                // Live Feed Optical Target Waveform Line Chart
                Expanded(
                  flex: 6,
                  child: _buildChartCard(
                    title: _timeRange.startsWith('Live')
                        ? 'Live Optical Target Waveform (CAM-01 Stream)'
                        : 'Historical Threat Frequency ($_timeRange)',
                    subtitle: _timeRange.startsWith('Live')
                        ? 'Continuous real-time optical target detections scrolling every 650ms from CAM-01'
                        : 'Aggregated target incursions across Sector 01 perimeter line',
                    badge: _buildWaveformBadges(state),
                    child: _buildTrendLineChart(state),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Row 2: Live Stream Performance Bar Chart + Live Classification Donut
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Stream Performance Bar Chart
                Expanded(
                  flex: 5,
                  child: _buildChartCard(
                    title: 'Live Optical Feed Sensor Performance & Throughput',
                    subtitle: 'Real-time hardware throughput, latency, bitrate, and virtual fence integrity',
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.radarGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${state.cam1Fps.toStringAsFixed(1)} FPS • ${state.liveLatencyMs}ms',
                        style: GoogleFonts.inter(color: AppTheme.radarGreen, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    child: _buildLiveTelemetryBarChart(state),
                  ),
                ),
                const SizedBox(width: 20),

                // Live Target Classification Donut Breakdown
                Expanded(
                  flex: 4,
                  child: _buildChartCard(
                    title: 'Live Target Classification Breakdown',
                    subtitle: 'Real-time object distribution computed from active camera stream',
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tacticalAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${state.cam1Counts['person']! + state.cam1Counts['vehicle']! + state.cam1Counts['face']! + state.cam1Counts['animal']!} IN FRAME',
                        style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    child: _buildClassificationDonutChart(state),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Row 3: Live Detection Event Stream & Telemetry Log
            _buildLiveEventStreamCard(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MockState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1050;
        final controls = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Camera Stream Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.charcoalSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.hairlineBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppTheme.charcoalSurface,
                  value: _selectedCameraId,
                  style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.bold, fontSize: 12),
                  icon: const Icon(Icons.videocam, color: AppTheme.tacticalAmber, size: 16),
                  items: [
                    const DropdownMenuItem(value: 'CAM-001', child: Text('CAM-001 (Laptop Cam • Live)')),
                    const DropdownMenuItem(value: 'CAM-002', child: Text('CAM-002 (North Perimeter)')),
                    const DropdownMenuItem(value: 'CAM-003', child: Text('CAM-003 (Watchtower Radar)')),
                    const DropdownMenuItem(value: 'CAM-004', child: Text('CAM-004 (South Gate)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedCameraId = v);
                      state.setSelectedAnalyticsCamera(v);
                    }
                  },
                ),
              ),
            ),

            // Time Range Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.charcoalSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.hairlineBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppTheme.charcoalSurface,
                  value: _timeRange,
                  style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontWeight: FontWeight.bold, fontSize: 12),
                  icon: const Icon(Icons.timeline, color: AppTheme.tacticalAmber, size: 16),
                  items: [
                    'Live Optical Stream (Real-Time)',
                    'Last 1 Hour (60m Window)',
                    'Today (Full Session)',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _timeRange = v);
                  },
                ),
              ),
            ),

            // Quick Camera Power Toggle
            ElevatedButton.icon(
              onPressed: () => state.toggleCameraPower(),
              icon: Icon(
                state.isCameraOn ? Icons.power_settings_new : Icons.videocam,
                size: 14,
                color: state.isCameraOn ? AppTheme.alertRed : AppTheme.obsidianBlack,
              ),
              label: Text(
                state.isCameraOn ? 'MUTE CAM' : 'ACTIVATE',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: state.isCameraOn ? AppTheme.alertRed : AppTheme.obsidianBlack,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isCameraOn ? AppTheme.alertRed.withValues(alpha: 0.15) : AppTheme.radarGreen,
                side: BorderSide(color: state.isCameraOn ? AppTheme.alertRed : AppTheme.radarGreen),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        );

        final titleCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Surveillance Intelligence & Analytics',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.titaniumWhite),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: (state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isCameraOn ? 'LIVE OPTICAL FEED • 650MS SYNC' : 'SENSOR MUTED • STANDBY',
                        style: GoogleFonts.inter(
                          color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time automated AI optical telemetry streams, camera sensor performance, and threat frequency',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedSilver),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleCol,
              const SizedBox(height: 14),
              controls,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleCol),
            const SizedBox(width: 16),
            controls,
          ],
        );
      },
    );
  }

  Widget _buildTelemetryStrip(MockState state) {
    final liveTotalTargets = (state.cam1Counts['person'] ?? 0) + (state.cam1Counts['vehicle'] ?? 0) + (state.cam1Counts['face'] ?? 0) + (state.cam1Counts['animal'] ?? 0);
    final activeAlertCount = state.alerts.where((a) => a.status == AlertStatus.active).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricItem(
              'CAM-01 Live In-Frame',
              '$liveTotalTargets Targets',
              liveTotalTargets > 0 ? AppTheme.tacticalAmber : AppTheme.radarGreen,
              Icons.center_focus_strong,
            ),
            _buildDivider(),
            _buildMetricItem(
              'Feed Frame Rate',
              state.isCameraOn ? '${state.cam1Fps.toStringAsFixed(1)} FPS' : 'Standby (Muted)',
              state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
              Icons.speed,
            ),
            _buildDivider(),
            _buildMetricItem(
              'Stream Throughput',
              state.isCameraOn ? '${state.liveBitrateKbps.toStringAsFixed(0)} kbps' : '0 kbps',
              AppTheme.titaniumWhite,
              Icons.wifi_tethering,
            ),
            _buildDivider(),
            _buildMetricItem(
              'AI Inference Latency',
              state.isCameraOn ? '${state.liveLatencyMs} ms' : 'N/A',
              state.liveLatencyMs < 60 ? AppTheme.radarGreen : AppTheme.tacticalAmber,
              Icons.bolt,
            ),
            _buildDivider(),
            _buildMetricItem(
              'Active Breach Signals',
              '$activeAlertCount Detected',
              activeAlertCount > 0 ? AppTheme.alertRed : AppTheme.radarGreen,
              Icons.warning_amber_rounded,
            ),
            _buildDivider(),
            _buildMetricItem(
              'AI Engine Mode',
              state.activeAiMode.toUpperCase(),
              AppTheme.tacticalAmber,
              Icons.psychology_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.hairlineBorder,
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.obsidianBlack,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveCameraCard(MockState state, Camera camera) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.tacticalAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      camera.id,
                      style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Stream Monitor • ${camera.name}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: (state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isCameraOn ? 'DIRECT FEED' : 'OFFLINE',
                      style: GoogleFonts.inter(
                        color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Embedded Live Video Feed
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LiveCameraFeed(camera: camera, fit: BoxFit.cover),

                  // Overlay Badge showing live detections
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: state.intrusionDetected ? AppTheme.alertRed : AppTheme.tacticalAmber.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            state.intrusionDetected ? Icons.warning : Icons.visibility,
                            size: 13,
                            color: state.intrusionDetected ? AppTheme.alertRed : AppTheme.tacticalAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            camera.currentDetection.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: state.intrusionDetected ? AppTheme.alertRed : AppTheme.titaniumWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick AI Mode Switcher Strip
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.hairlineBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('AI FILTER:', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 9, fontWeight: FontWeight.bold)),
                          ...['all', 'fence', 'detection', 'face', 'anpr'].map((m) {
                            final isActive = state.activeAiMode == m;
                            return InkWell(
                              onTap: () => state.setAiMode(m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.tacticalAmber : Colors.transparent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  m.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: isActive ? AppTheme.obsidianBlack : AppTheme.titaniumWhite,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformBadges(MockState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.cam1Counts['person']! > 0)
          _buildBadgeTag('${state.cam1Counts['person']!} HUMANS', AppTheme.tacticalAmber),
        if (state.cam1Counts['vehicle']! > 0) ...[
          const SizedBox(width: 6),
          _buildBadgeTag('${state.cam1Counts['vehicle']!} VEHICLES', AppTheme.titaniumWhite),
        ],
        if (state.cam1Counts['face']! > 0) ...[
          const SizedBox(width: 6),
          _buildBadgeTag('${state.cam1Counts['face']!} FACES', const Color(0xFF60A5FA)),
        ],
        if (state.intrusionDetected) ...[
          const SizedBox(width: 6),
          _buildBadgeTag('BREACH SPIKE', AppTheme.alertRed),
        ],
      ],
    );
  }

  Widget _buildBadgeTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChartCard({required String title, required String subtitle, Widget? badge, required Widget child}) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTrendLineChart(MockState state) {
    List<FlSpot> spots;
    List<String> labels;

    final isLiveMode = _timeRange.startsWith('Live');

    if (isLiveMode) {
      // Direct real-time live feed spots (24 rolling samples from CAM-01 polled every 650ms)
      spots = state.liveFeedHistory;
      labels = ['-15s', '-13s', '-11s', '-9s', '-7s', '-5s', '-3s', '-1s', 'LIVE NOW'];
    } else if (_timeRange.startsWith('Last 1 Hour')) {
      labels = ['-60m', '-50m', '-40m', '-30m', '-20m', '-10m', 'Now'];
      final current = (state.cam1Counts['person'] ?? 0) + (state.cam1Counts['vehicle'] ?? 0);
      spots = [
        const FlSpot(0, 1),
        const FlSpot(1, 2),
        const FlSpot(2, 1),
        const FlSpot(3, 3),
        const FlSpot(4, 2),
        const FlSpot(5, 4),
        FlSpot(6, (current > 0 ? current.toDouble() : 2.0)),
      ];
    } else {
      labels = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', 'Now'];
      final current = (state.cam1Counts['person'] ?? 0) + (state.cam1Counts['vehicle'] ?? 0);
      spots = [
        const FlSpot(0, 2),
        const FlSpot(1, 4),
        const FlSpot(2, 3),
        const FlSpot(3, 7),
        const FlSpot(4, 5),
        const FlSpot(5, 8),
        FlSpot(6, (current > 0 ? (current + 5).toDouble() : 6.0)),
      ];
    }

    final maxSpotY = spots.map((s) => s.y).fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);
    final maxY = (maxSpotY + 2.0).clamp(5.0, 25.0);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()} Targets Detected\nLive Optical Telemetry',
                  GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.subtleBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: isLiveMode ? 3.0 : 1.0,
              getTitlesWidget: (val, meta) {
                final idx = isLiveMode ? (val / 3).round() : val.toInt();
                if (idx >= 0 && idx < labels.length) {
                  final isNow = labels[idx].contains('NOW') || labels[idx].contains('Now');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: GoogleFonts.inter(
                        color: isNow ? AppTheme.tacticalAmber : AppTheme.mutedSilver,
                        fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY > 10 ? 5 : 1,
              getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 10)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: state.intrusionDetected ? AppTheme.alertRed : AppTheme.tacticalAmber,
            barWidth: 2.6,
            dotData: FlDotData(
              show: !isLiveMode,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: AppTheme.tacticalAmber,
                  strokeColor: AppTheme.charcoalSurface,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (state.intrusionDetected ? AppTheme.alertRed : AppTheme.tacticalAmber).withValues(alpha: 0.28),
                  (state.intrusionDetected ? AppTheme.alertRed : AppTheme.tacticalAmber).withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryBarChart(MockState state) {
    // 5 Live Stream Throughput & Sensor Metrics:
    // 1. Live Frame Rate (FPS) normalized out of 30 fps
    final fpsValue = (state.isCameraOn ? (state.cam1Fps / 30.0 * 100.0) : 0.0).clamp(0.0, 100.0);

    // 2. Optical Stream Bitrate (normalized out of 3000 kbps)
    final bitrateValue = (state.liveBitrateKbps / 3000.0 * 100.0).clamp(0.0, 100.0);

    // 3. AI Processing Efficiency (100% at 20ms, drops if latency > 80ms)
    final aiEfficiency = state.isCameraOn ? ((100.0 - state.liveLatencyMs).clamp(20.0, 100.0)) : 0.0;

    // 4. Live Optical Target Ingestion Index
    final currentTargets = (state.cam1Counts['person']! + state.cam1Counts['vehicle']! + state.cam1Counts['face']! + state.cam1Counts['animal']!);
    final targetIndex = (currentTargets * 25.0).clamp(0.0, 100.0);

    // 5. Perimeter Virtual Fence Integrity (100% nominal, 15% on intrusion breach)
    final fenceIntegrity = state.intrusionDetected ? 15.0 : (state.isCameraOn ? 100.0 : 40.0);

    final barItems = [
      {'label': 'Feed FPS (${state.cam1Fps.toStringAsFixed(0)})', 'val': fpsValue, 'color': AppTheme.radarGreen},
      {'label': 'Bitrate (${(state.liveBitrateKbps / 1000).toStringAsFixed(1)}M)', 'val': bitrateValue, 'color': AppTheme.tacticalAmber},
      {'label': 'AI Speed (${state.liveLatencyMs}ms)', 'val': aiEfficiency, 'color': const Color(0xFF60A5FA)},
      {'label': 'Target Load', 'val': targetIndex > 0 ? targetIndex : 5.0, 'color': targetIndex > 0 ? AppTheme.tacticalAmber : AppTheme.disabledGrey},
      {'label': 'Perimeter Fence', 'val': fenceIntegrity, 'color': state.intrusionDetected ? AppTheme.alertRed : AppTheme.radarGreen},
    ];

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.subtleBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < barItems.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      barItems[idx]['label'] as String,
                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 25,
              getTitlesWidget: (val, meta) => Text('${val.toInt()}%', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 9)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(barItems.length, (i) {
          final item = barItems[i];
          final val = (item['val'] as num).toDouble();
          final color = item['color'] as Color;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: color,
                width: 28,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildClassificationDonutChart(MockState state) {
    int liveP = (state.cam1Counts['person'] ?? 0);
    int liveV = (state.cam1Counts['vehicle'] ?? 0);
    int liveF = (state.cam1Counts['face'] ?? 0);
    int liveA = (state.cam1Counts['animal'] ?? 0);

    int totalP = liveP + state.totalPersonsDetected;
    int totalV = liveV + state.totalVehiclesDetected;
    int totalF = liveF + state.totalFacesDetected;
    int totalA = liveA + state.totalAnimalsDetected;
    int grandTotal = totalP + totalV + totalF + totalA;

    if (grandTotal == 0) grandTotal = 1;

    double pPct = (totalP / grandTotal * 100);
    double vPct = (totalV / grandTotal * 100);
    double fPct = (totalF / grandTotal * 100);
    double aPct = (totalA / grandTotal * 100);

    final sections = <PieChartSectionData>[];
    if (pPct > 0) {
      sections.add(PieChartSectionData(
        color: AppTheme.tacticalAmber,
        value: pPct,
        title: '${pPct.toInt()}%',
        titleStyle: GoogleFonts.inter(color: AppTheme.obsidianBlack, fontWeight: FontWeight.w900, fontSize: 11),
        radius: 46,
      ));
    }
    if (vPct > 0) {
      sections.add(PieChartSectionData(
        color: AppTheme.titaniumWhite,
        value: vPct,
        title: '${vPct.toInt()}%',
        titleStyle: GoogleFonts.inter(color: AppTheme.obsidianBlack, fontWeight: FontWeight.w900, fontSize: 11),
        radius: 42,
      ));
    }
    if (fPct > 0) {
      sections.add(PieChartSectionData(
        color: const Color(0xFF60A5FA),
        value: fPct,
        title: '${fPct.toInt()}%',
        titleStyle: GoogleFonts.inter(color: AppTheme.obsidianBlack, fontWeight: FontWeight.w900, fontSize: 11),
        radius: 40,
      ));
    }
    if (aPct > 0) {
      sections.add(PieChartSectionData(
        color: AppTheme.radarGreen,
        value: aPct,
        title: '${aPct.toInt()}%',
        titleStyle: GoogleFonts.inter(color: AppTheme.obsidianBlack, fontWeight: FontWeight.w900, fontSize: 11),
        radius: 38,
      ));
    }

    final liveInFrame = liveP + liveV + liveF + liveA;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: sections,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$liveInFrame',
                    style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    'IN FRAME',
                    style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendRow(AppTheme.tacticalAmber, 'Persons (Live: $liveP)', '$totalP total'),
              const SizedBox(height: 8),
              _buildLegendRow(AppTheme.titaniumWhite, 'Vehicles (Live: $liveV)', '$totalV total'),
              const SizedBox(height: 8),
              _buildLegendRow(const Color(0xFF60A5FA), 'Faces (Live: $liveF)', '$totalF total'),
              const SizedBox(height: 8),
              _buildLegendRow(AppTheme.radarGreen, 'Fauna / Wildlife', '$totalA total'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(value, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLiveEventStreamCard(MockState state) {
    final events = state.liveFeedEvents;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stream, color: AppTheme.radarGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Live Optical Telemetry & Event Ingestion Stream',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.radarGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${events.length} LOGGED EVENTS',
                  style: GoogleFonts.inter(color: AppTheme.radarGreen, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chronological stream of verified targets, incursions, and AI neural detections from CAM-01',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
          ),
          const SizedBox(height: 16),

          if (events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Waiting for live optical detections from CAM-01...',
                  style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.take(5).length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.hairlineBorder, height: 16),
              itemBuilder: (context, index) {
                final ev = events[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ev.badgeColor.withValues(alpha: 0.5)),
                      ),
                      child: Icon(ev.icon, size: 16, color: ev.badgeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ev.title,
                                style: GoogleFonts.inter(
                                  color: AppTheme.titaniumWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: ev.badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: ev.badgeColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '${ev.confidence}% CONF',
                                  style: GoogleFonts.inter(color: ev.badgeColor, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Node: ${ev.cameraId} • Location: ${ev.location}',
                            style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatEventTime(ev.timestamp),
                      style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatEventTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
