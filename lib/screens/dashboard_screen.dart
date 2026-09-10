import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../mock/mock_state.dart';
import '../models/camera.dart';
import '../models/alert.dart';
import '../theme/app_theme.dart';
import '../widgets/live_camera_feed.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatUtcTime(DateTime dt) {
    final utc = dt.toUtc();
    final h = utc.hour.toString().padLeft(2, '0');
    final m = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$h:$m:$s Z';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final primaryCam = state.cameras.firstWhere(
      (c) => c.id == state.selectedDashboardCameraId,
      orElse: () => state.cameras.first,
    );

    return Container(
      color: AppTheme.obsidianBlack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tactical Command & Sector Header
            _buildMilitaryHeader(state),
            const SizedBox(height: 20),

            // 2. 4-Card Tactical Readiness Deck
            _buildReadinessDeck(state),
            const SizedBox(height: 20),

            // 3. Main Split Deck: Left Hero Viewport (6) + Right Threat Operations (4)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 980) {
                  // Stack vertically on narrower windows
                  return Column(
                    children: [
                      _buildSurveillanceColumn(state, primaryCam),
                      const SizedBox(height: 20),
                      _buildThreatOperationsColumn(state),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Surveillance & Waveform)
                    Expanded(
                      flex: 6,
                      child: _buildSurveillanceColumn(state, primaryCam),
                    ),
                    const SizedBox(width: 20),
                    // Right Column (Threat Feed & QRT Dispatch)
                    Expanded(
                      flex: 4,
                      child: _buildThreatOperationsColumn(state),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Military Header Bar ---
  Widget _buildMilitaryHeader(MockState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 980;

        final titleAndStatus = Row(
          children: [
            // Left military badge & mission status
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.obsidianBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.7)),
              ),
              child: const Icon(Icons.shield, color: AppTheme.tacticalAmber, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'TACTICAL C2 OPERATIONS ROOM',
                          style: GoogleFonts.inter(
                            fontSize: constraints.maxWidth < 650 ? 15 : 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.titaniumWhite,
                            letterSpacing: 0.6,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.radarGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.radarGreen),
                        ),
                        child: Text(
                          'GRID ARMED',
                          style: GoogleFonts.inter(
                            color: AppTheme.radarGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'SECTOR 07 • NORTHERN CORRIDOR | COORD: 34°12\'44"N 74°28\'10"E | REAL-TIME OPTICAL SENSORS',
                    style: GoogleFonts.inter(
                      color: AppTheme.mutedSilver,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final clocksAndDefcon = Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Military Clocks
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.obsidianBlack,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.hairlineBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppTheme.tacticalAmber),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatTime(_currentTime)} IST',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.titaniumWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${_formatUtcTime(_currentTime)}',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.mutedSilver,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Dynamic DEFCON Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: state.defconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: state.defconColor, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: state.defconColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.defconColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.defconStatus,
                    style: GoogleFonts.inter(
                      color: state.defconColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.hairlineBorder),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleAndStatus,
                    const SizedBox(height: 14),
                    clocksAndDefcon,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleAndStatus),
                    const SizedBox(width: 14),
                    clocksAndDefcon,
                  ],
                ),
        );
      },
    );
  }

  // --- 2. 4-Card Tactical Readiness Deck ---
  Widget _buildReadinessDeck(MockState state) {
    final bool hasBreach = state.intrusionDetected;
    final int personCount = state.cam1Counts['person'] ?? 0;
    final int vehicleCount = state.cam1Counts['vehicle'] ?? 0;
    final int totalTargets = personCount + vehicleCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        double cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _buildTacticalKpiCard(
              width: cardWidth,
              title: 'PERIMETER DEFENSE',
              value: hasBreach ? 'BREACH FLAGGED' : 'ARMED & SECURE',
              subtitle: hasBreach ? 'Sector 01 Incursion Active' : 'Tripwire AI Active • 0 Bypasses',
              icon: hasBreach ? Icons.warning_rounded : Icons.verified_user_rounded,
              color: hasBreach ? AppTheme.alertRed : AppTheme.radarGreen,
            ),
            _buildTacticalKpiCard(
              width: cardWidth,
              title: 'ACTIVE TARGETS IN SECTOR',
              value: totalTargets > 0 ? '$personCount PERSONS • $vehicleCount VEHICLES' : '0 INTRUDERS',
              subtitle: 'YOLOv11 Real-Time Vision Feed',
              icon: Icons.track_changes_rounded,
              color: totalTargets > 0 ? AppTheme.tacticalAmber : AppTheme.radarGreen,
            ),
            _buildTacticalKpiCard(
              width: cardWidth,
              title: 'OPTICAL SENSOR CAM-01',
              value: state.isCameraOn ? '${state.cam1Fps.toStringAsFixed(0)} FPS • 1080p' : 'HARDWARE STANDBY',
              subtitle: state.isCameraOn ? 'Latency: ${state.liveLatencyMs}ms • Direct Stream' : 'Camera Sensor Powered Off',
              icon: state.isCameraOn ? Icons.videocam_rounded : Icons.power_settings_new,
              color: state.isCameraOn ? AppTheme.radarGreen : AppTheme.alertRed,
            ),
            _buildTacticalKpiCard(
              width: cardWidth,
              title: 'NEURAL AI PIPELINE',
              value: state.activeAiMode.toUpperCase(),
              subtitle: 'Tripwire + Haar Face Biometrics',
              icon: Icons.memory_rounded,
              color: const Color(0xFF60A5FA),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTacticalKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.hairlineBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.obsidianBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mutedSilver,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.titaniumWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Left Surveillance Viewport & Telemetry Waveform ---
  Widget _buildSurveillanceColumn(MockState state, Camera primaryCam) {
    final bool isCam2 = primaryCam.id == 'CAM-002';
    final bool hasBreach = state.intrusionDetected;
    final int personCount = isCam2 ? (state.cam2Counts['person'] ?? 0) : (state.cam1Counts['person'] ?? 0);
    final int vehicleCount = isCam2 ? (state.cam2Counts['vehicle'] ?? 0) : (state.cam1Counts['vehicle'] ?? 0);
    final double activeFps = isCam2 ? state.cam2Fps : state.cam1Fps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Viewport Container with Tactical HUD Styling
        Container(
          decoration: BoxDecoration(
            color: AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasBreach
                  ? AppTheme.alertRed
                  : AppTheme.tacticalAmber.withValues(alpha: 0.6),
              width: hasBreach ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (hasBreach ? AppTheme.alertRed : AppTheme.tacticalAmber).withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar over Video Viewport
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.obsidianBlack,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                  border: Border(bottom: BorderSide(color: AppTheme.hairlineBorder)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isCameraOn ? (isCam2 ? AppTheme.tacticalAmber : AppTheme.radarGreen) : AppTheme.alertRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CHANNEL:',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.mutedSilver,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildChannelSelectorChip(state, 'CAM-01 • LAPTOP', 'CAM-001', state.cam1DeviceName),
                      const SizedBox(width: 6),
                      _buildChannelSelectorChip(state, 'CAM-02 • PHONE RECON', 'CAM-002', state.cam2DeviceName),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await state.swapCameras();
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 14, color: AppTheme.obsidianBlack),
                        label: Text(
                          'SWAP',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: AppTheme.obsidianBlack,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tacticalAmber,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Quick phone source config button
                      IconButton(
                        icon: const Icon(Icons.usb_rounded, size: 16, color: AppTheme.tacticalAmber),
                        tooltip: 'Configure Phone Camera Source (Direct USB / IP)',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showCameraSourceDialog(context, state),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.charcoalElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.hairlineBorder),
                        ),
                        child: Text(
                          state.isCameraOn ? '${activeFps.toStringAsFixed(1)} FPS • 1080p' : 'OFFLINE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: state.isCameraOn ? (isCam2 ? AppTheme.tacticalAmber : AppTheme.radarGreen) : AppTheme.alertRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Live Video Frame Viewport
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video Stream Widget
                      LiveCameraFeed(camera: primaryCam, isModal: true),

                      // Tactical Reticle Corners Overlay
                      _buildTacticalReticleOverlay(),

                      // Top-right Live Target Tags
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (hasBreach)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.alertRed,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black54, blurRadius: 6),
                                  ],
                                ),
                                child: Text(
                                  'PERIMETER BREACH ACTIVE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            else if (personCount > 0 || vehicleCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.tacticalAmber,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black54, blurRadius: 6),
                                  ],
                                ),
                                child: Text(
                                  '$personCount HUMAN • $vehicleCount VEHICLE DETECTED',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.obsidianBlack,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.obsidianBlack.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.7)),
                                ),
                                child: Text(
                                  'SECTOR SECURE • TRIPWIRE ARMED',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.radarGreen,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Viewport Controls: AI Model Switch Chips & Power Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppTheme.obsidianBlack,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
                  border: Border(top: BorderSide(color: AppTheme.hairlineBorder)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'AI ENGINE:',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.mutedSilver,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // AI Mode selector chips
                      _buildAiChip(state, 'ALL-DOMAIN', 'all'),
                      const SizedBox(width: 6),
                      _buildAiChip(state, 'HUMAN', 'person'),
                      const SizedBox(width: 6),
                      _buildAiChip(state, 'VEHICLE', 'vehicle'),
                      const SizedBox(width: 6),
                      _buildAiChip(state, 'FACE ID', 'face'),
                      const SizedBox(width: 6),
                      _buildAiChip(state, 'TRIPWIRE', 'fence'),

                      const SizedBox(width: 14),

                      // Camera Power Toggle Button
                      ElevatedButton.icon(
                      onPressed: () => state.toggleCameraPower(),
                      icon: Icon(
                        state.isCameraOn ? Icons.power_settings_new : Icons.videocam,
                        size: 14,
                        color: state.isCameraOn ? AppTheme.alertRed : AppTheme.obsidianBlack,
                      ),
                      label: Text(
                        state.isCameraOn ? 'STANDBY' : 'ACTIVATE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Optical Telemetry Waveform Card
        _buildWaveformCard(state),
      ],
    );
  }

  Widget _buildAiChip(MockState state, String label, String modeKey) {
    final bool isSelected = state.activeAiMode.toLowerCase() == modeKey.toLowerCase();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('[AI CHIP] User switched AI mode to: $modeKey');
          state.setAiMode(modeKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.tacticalAmber : AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected ? AppTheme.tacticalAmber : AppTheme.hairlineBorder,
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.tacticalAmber.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.obsidianBlack,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppTheme.obsidianBlack : AppTheme.titaniumWhite,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelSelectorChip(MockState state, String label, String camId, String hardwareDevice) {
    final bool isSelected = state.selectedDashboardCameraId == camId;
    final String cleanDev = hardwareDevice.contains('(')
        ? hardwareDevice.split('(').first.trim()
        : hardwareDevice.replaceAll('USB 2.0', '').replaceAll('Webcam', 'Cam').trim();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('[OPTICAL CHANNEL] Switched to $camId');
          state.selectDashboardCamera(camId);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? (camId == 'CAM-002' ? AppTheme.tacticalAmber : AppTheme.radarGreen) : AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? (camId == 'CAM-002' ? AppTheme.tacticalAmber : AppTheme.radarGreen) : AppTheme.hairlineBorder,
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (camId == 'CAM-002' ? AppTheme.tacticalAmber : AppTheme.radarGreen).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.obsidianBlack,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                '$label [$cleanDev]',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppTheme.obsidianBlack : AppTheme.titaniumWhite,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCameraSourceDialog(BuildContext context, MockState state) {
    final controller = TextEditingController(text: state.cam2Source);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.obsidianBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.tacticalAmber, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.usb_rounded, color: AppTheme.tacticalAmber, size: 20),
              const SizedBox(width: 8),
              Text(
                'PHONE RECON CAMERA SOURCE CONFIG',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.titaniumWhite,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign hardware device index or stream URL for CAM-02 (Mobile Recon Node):',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppTheme.titaniumWhite),
                  decoration: InputDecoration(
                    labelText: 'DEVICE INDEX OR STREAM URL',
                    labelStyle: GoogleFonts.inter(fontSize: 10, color: AppTheme.tacticalAmber, fontWeight: FontWeight.bold),
                    hintText: 'e.g. 1 (for USB) or http://192.168.42.129:8080/video',
                    hintStyle: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
                    filled: true,
                    fillColor: AppTheme.charcoalSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.hairlineBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.tacticalAmber)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('QUICK PRESETS (OFFLINE DIRECT USB):', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedSilver)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip('USB Index 1 (Iriun / DroidCam)', '1', controller),
                    _buildPresetChip('USB Index 2', '2', controller),
                    _buildPresetChip('USB Tethering IP', 'http://192.168.42.129:8080/video', controller),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.charcoalSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.tacticalAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For zero-network offline demo: Connect phone with USB data cable and open Iriun 4K Webcam or DroidCam on both PC & phone.',
                          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedSilver),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tacticalAmber,
                foregroundColor: AppTheme.obsidianBlack,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () async {
                final source = controller.text.trim();
                if (source.isNotEmpty) {
                  await state.updateCameraSource('CAM-002', source);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: Text('ACTIVATE SOURCE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPresetChip(String label, String value, TextEditingController controller) {
    return InkWell(
      onTap: () {
        controller.text = value;
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.charcoalElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.hairlineBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: AppTheme.titaniumWhite, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Reticle overlay
  Widget _buildTacticalReticleOverlay() {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCornerBracket(top: true, left: true),
                _buildCornerBracket(top: true, left: false),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCornerBracket(top: false, left: true),
                _buildCornerBracket(top: false, left: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({required bool top, required bool left}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppTheme.tacticalAmber, width: 2) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppTheme.tacticalAmber, width: 2) : BorderSide.none,
          left: left ? const BorderSide(color: AppTheme.tacticalAmber, width: 2) : BorderSide.none,
          right: !left ? const BorderSide(color: AppTheme.tacticalAmber, width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  // Real-Time Waveform Card
  Widget _buildWaveformCard(MockState state) {
    final bool hasBreach = state.intrusionDetected;
    final Color primaryColor = hasBreach ? AppTheme.alertRed : AppTheme.tacticalAmber;
    final spots = state.detectionHistory;
    final double maxY = spots.map((s) => s.y).fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);
    final double dynamicMaxY = (maxY + 2.0).clamp(5.0, 30.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.show_chart, size: 16, color: AppTheme.tacticalAmber),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'REAL-TIME OPTICAL INTRUSION WAVEFORM (TELEMETRY)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.titaniumWhite,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  hasBreach ? 'BREACH DETECTED' : 'STREAM NOMINAL',
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chart
          SizedBox(
            height: 115,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: dynamicMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.subtleBorder, strokeWidth: 1),
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
                      interval: dynamicMaxY > 8 ? 4 : 1,
                      getTitlesWidget: (val, _) => Text(
                        val.toInt().toString(),
                        style: GoogleFonts.jetBrainsMono(color: AppTheme.mutedSilver, fontSize: 9),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: primaryColor,
                    barWidth: 2.2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Breakdown telemetry strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.obsidianBlack,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.hairlineBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatPill('Humans', '${state.cam1Counts['person'] ?? 0}'),
                _buildStatPill('Vehicles', '${state.cam1Counts['vehicle'] ?? 0}'),
                _buildStatPill('Animals', '${state.cam1Counts['animal'] ?? 0}'),
                _buildStatPill('Faces', '${state.cam1Counts['face'] ?? 0}'),
                _buildStatPill('Bitrate', '${state.liveBitrateKbps.toStringAsFixed(0)} Kbps'),
                _buildStatPill('Security', 'SECURE'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 9)),
        const SizedBox(height: 1),
        Text(value, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- 4. Right Threat Operations & QRT Dispatch Deck ---
  Widget _buildThreatOperationsColumn(MockState state) {
    final activeAlerts = state.alerts.where((a) => a.status == AlertStatus.active).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Threat Incursions Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.hairlineBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, size: 18, color: AppTheme.alertRed),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'LIVE PERIMETER THREAT LOG',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.titaniumWhite,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeAlerts.isNotEmpty
                          ? AppTheme.alertRed.withValues(alpha: 0.15)
                          : AppTheme.radarGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: activeAlerts.isNotEmpty ? AppTheme.alertRed : AppTheme.radarGreen,
                      ),
                    ),
                    child: Text(
                      '${activeAlerts.length} ACTIVE',
                      style: GoogleFonts.inter(
                        color: activeAlerts.isNotEmpty ? AppTheme.alertRed : AppTheme.radarGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Threat Items
              if (activeAlerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.radarGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppTheme.radarGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ALL SECTORS SECURE',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppTheme.titaniumWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Optical stream CAM-01 active. No unauthorized boundary crossings detected.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppTheme.mutedSilver,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...activeAlerts.take(3).map((alert) => _buildAlertItem(state, alert)),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // QRT Quick Deployment Deck
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.hairlineBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded, size: 20, color: AppTheme.tacticalAmber),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'QUICK REACTION TEAM (QRT) COMMAND',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.titaniumWhite,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Rapid tactical deployment to active coordinates',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
              ),
              const SizedBox(height: 14),

              // Sector Status Strip
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianBlack,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.hairlineBorder),
                ),
                child: Column(
                  children: [
                    _buildSectorStatusRow('Sector 01 (Command Post)', 'PATROL ON POST', AppTheme.radarGreen),
                    const Divider(color: AppTheme.subtleBorder, height: 12),
                    _buildSectorStatusRow('Sector 02 (Eastern Ridge)', 'PATROL READY', AppTheme.tacticalAmber),
                    const Divider(color: AppTheme.subtleBorder, height: 12),
                    _buildSectorStatusRow('Sector 03 (Northern Pass)', 'UAV MONITORED', AppTheme.radarGreen),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Deployment Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deployQrt(context, state),
                      icon: const Icon(Icons.send_rounded, size: 16, color: AppTheme.obsidianBlack),
                      label: Text(
                        'DISPATCH QRT PATROL',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: AppTheme.obsidianBlack,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tacticalAmber,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      state.toggleAudibleSiren(!state.audibleSiren);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.audibleSiren ? 'PERIMETER SIREN ARMED' : 'PERIMETER SIREN MUTED'),
                          backgroundColor: AppTheme.charcoalElevated,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: state.audibleSiren ? AppTheme.alertRed : AppTheme.mutedSilver,
                      side: BorderSide(color: state.audibleSiren ? AppTheme.alertRed : AppTheme.hairlineBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Icon(
                      state.audibleSiren ? Icons.campaign_rounded : Icons.campaign_outlined,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(MockState state, Alert alert) {
    final bool isCritical = alert.severity == AlertSeverity.critical;
    final Color accentColor = isCritical ? AppTheme.alertRed : AppTheme.tacticalAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.obsidianBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  isCritical ? 'CRITICAL ALPHA' : 'PRIORITY BRAVO',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${alert.detectedAt.hour.toString().padLeft(2, '0')}:${alert.detectedAt.minute.toString().padLeft(2, '0')}:${alert.detectedAt.second.toString().padLeft(2, '0')}',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppTheme.mutedSilver),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alert.title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppTheme.titaniumWhite,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${alert.cameraId} • ${alert.location}',
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedSilver),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => state.acknowledgeAlert(alert.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'ACKNOWLEDGE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tacticalAmber,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectorStatusRow(String sector, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          sector,
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.titaniumWhite, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  void _deployQrt(BuildContext context, MockState state) {
    state.dispatchPatrol(
      sector: 'Sector 01 (Command Post)',
      threatType: 'Perimeter Sweep Patrol',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.radarGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'QRT PATROL ALPHA DEPLOYED TO SECTOR 01',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoalElevated,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
