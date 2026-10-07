import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../mock/mock_state.dart';
import '../models/alert.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  bool _isDispatchHovered = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _showDispatchDialog(BuildContext context, MockState state) {
    String selectedSector = 'Sector 01 (Command Post)';
    String priority = 'Critical Alpha';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.charcoalSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.hairlineBorder, width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.send_rounded, color: AppTheme.uiAmber, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Dispatch Quick Reaction Team',
                    style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authorize immediate event ground patrol deployment to sector coordinates.',
                      style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    Text('Target Security Sector', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.hairlineBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedSector,
                          dropdownColor: AppTheme.charcoalElevated,
                          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                          items: [
                            'Sector 01 (Command Post)',
                            'Sector 02 (East Basin)',
                            'Sector 03 (West Ridge)',
                          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) {
                            if (v != null) setModalState(() => selectedSector = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Escalation Priority', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.hairlineBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: priority,
                          dropdownColor: AppTheme.charcoalElevated,
                          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                          items: [
                            'Critical Alpha (Armed Breach Protocol)',
                            'High Priority (Perimeter Reconnaissance)',
                            'Routine Patrol (Perimeter Integrity Check)',
                          ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) {
                            if (v != null) setModalState(() => priority = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('ABORT', style: GoogleFonts.inter(color: AppTheme.mutedSilver)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.uiAmber,
                    foregroundColor: AppTheme.obsidianBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () {
                    state.dispatchPatrol(sector: selectedSector, threatType: priority);
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Quick Reaction Patrol dispatched to $selectedSector. Incident logged.'),
                        backgroundColor: AppTheme.charcoalElevated,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('AUTHORIZE DISPATCH', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final hasThreat = state.intrusionDetected || state.alerts.any((a) => a.status == AlertStatus.active);
    final activeAlertCount = state.alerts.where((a) => a.status == AlertStatus.active).length;

    return Container(
      color: AppTheme.obsidianBlack,
      child: Row(
        children: [
          // Event Map Canvas with animated radar sweep
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _EventRadarPainter(
                        animationProgress: _radarController.value,
                        hasThreat: hasThreat,
                        isCameraOnline: state.isCameraOn && state.isBackendConnected,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                // Legend Overlay
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoalSurface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.hairlineBorder),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.uiAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'EVENT RADAR TELEMETRY',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.uiAmber,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(AppTheme.radarGreen, 'Sector 01 CAM-01 Sensor Node'),
                        _buildLegendItem(AppTheme.titaniumWhite, 'Primary Perimeter Management Line'),
                        _buildLegendItem(hasThreat ? AppTheme.alertRed : AppTheme.mutedSilver, hasThreat ? 'Active Incursion Signal Detected' : 'Perimeter Clear (No Breach)'),
                        _buildLegendItem(AppTheme.uiAmber, 'Active Radar Sweep Vector'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right Control Panel
          Container(
            width: 330,
            decoration: const BoxDecoration(
              color: AppTheme.charcoalSurface,
              border: Border(left: BorderSide(color: AppTheme.hairlineBorder)),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SECTOR TELEMETRY',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.uiAmber, fontSize: 11, letterSpacing: 0.8),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: state.defconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: state.defconColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        hasThreat ? 'ALERT LEVEL ELEVATED' : 'NOMINAL',
                        style: GoogleFonts.inter(color: state.defconColor, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Sector 01 Event Zone', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                const SizedBox(height: 4),
                Text('MGRS: 43R EN 2819 1485 • Laptop Post', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.hairlineBorder),
                const SizedBox(height: 14),
                _buildZoneDetail('Operational Sensor Inputs', '${state.cameras.where((c) => !c.isEmptySlot).length} Active Feed (${state.cameras.where((c) => c.isEmptySlot).length} Standby Slots)'),
                _buildZoneDetail('Active Breach Signals', '$activeAlertCount Active Alerts', color: activeAlertCount > 0 ? AppTheme.alertRed : AppTheme.radarGreen),
                _buildZoneDetail('Radar Pulse Sweep Rate', '3.5s Continuous Sweep'),
                _buildZoneDetail('Sensor Latency', state.isBackendConnected ? '${(1000 / (state.cam1Fps > 0 ? state.cam1Fps : 30)).toStringAsFixed(0)}ms (Direct AI Link)' : 'Offline'),
                _buildZoneDetail('Assigned Quick Reaction Team', 'Delta-9 Quick Reaction Unit'),
                _buildZoneDetail('DEFCON Status', state.defconStatus.split('•').first.trim(), color: state.defconColor),
                const Spacer(),
                // Dispatch Button with smooth hover animation
                MouseRegion(
                  onEnter: (_) => setState(() => _isDispatchHovered = true),
                  onExit: (_) => setState(() => _isDispatchHovered = false),
                  child: AnimatedScale(
                    scale: _isDispatchHovered ? 1.02 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.uiAmber.withValues(alpha: _isDispatchHovered ? 0.4 : 0.2),
                            blurRadius: _isDispatchHovered ? 16 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.uiAmber,
                          foregroundColor: AppTheme.obsidianBlack,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showDispatchDialog(context, state),
                        icon: const Icon(Icons.send_rounded, size: 18, color: AppTheme.obsidianBlack),
                        label: Text(
                          'DISPATCH RAPID PATROL',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.titaniumWhite)),
        ],
      ),
    );
  }

  Widget _buildZoneDetail(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: color ?? AppTheme.titaniumWhite),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRadarPainter extends CustomPainter {
  final double animationProgress;
  final bool hasThreat;
  final bool isCameraOnline;

  _EventRadarPainter({
    required this.animationProgress,
    required this.hasThreat,
    required this.isCameraOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final gridPaint = Paint()
      ..color = AppTheme.hairlineBorder.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 45) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 45) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Border Fence Path
    final borderPaint = Paint()
      ..color = AppTheme.titaniumWhite.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.45, size.width, size.height * 0.25);
    canvas.drawPath(path, borderPaint);

    // Online nodes with green glowing halo
    final nodeColor = isCameraOnline ? AppTheme.radarGreen : AppTheme.alertRed;
    final nodePaint = Paint()..color = nodeColor;
    final nodeHalo = Paint()..color = nodeColor.withValues(alpha: 0.25);

    // Primary Laptop Node (CAM-001)
    final primaryNode = Offset(size.width * 0.35, size.height * 0.40);
    canvas.drawCircle(primaryNode, 12, nodeHalo);
    canvas.drawCircle(primaryNode, 6, nodePaint);

    // Vacant/Standby nodes shown with dotted/hollow markers
    final vacantNodes = [
      Offset(size.width * 0.65, size.height * 0.34),
      Offset(size.width * 0.85, size.height * 0.28),
    ];
    final vacantPaint = Paint()
      ..color = AppTheme.mutedSilver.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var v in vacantNodes) {
      canvas.drawCircle(v, 5, vacantPaint);
    }

    // Radar Center
    final radarCenter = primaryNode;
    final radarRadius = math.min(size.width, size.height) * 0.38;

    // Concentric range rings
    final ringPaint = Paint()
      ..color = (hasThreat ? AppTheme.alertRed : AppTheme.radarGreen).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(radarCenter, radarRadius * 0.33, ringPaint);
    canvas.drawCircle(radarCenter, radarRadius * 0.66, ringPaint);
    canvas.drawCircle(radarCenter, radarRadius, ringPaint);

    // Rotating Radar Sweep Line
    double angle = animationProgress * 2 * math.pi;
    final sweepEnd = Offset(
      radarCenter.dx + radarRadius * math.cos(angle),
      radarCenter.dy + radarRadius * math.sin(angle),
    );

    final sweepLinePaint = Paint()
      ..color = AppTheme.uiAmber.withValues(alpha: 0.7)
      ..strokeWidth = 1.6;
    canvas.drawLine(radarCenter, sweepEnd, sweepLinePaint);

    // Active Threat Beacon (Only painted if an actual threat/incident is active)
    if (hasThreat) {
      final threatCenter = Offset(size.width * 0.48, size.height * 0.36);
      double threatPulse = (animationProgress * 30.0);
      final pulsePaint = Paint()
        ..color = AppTheme.alertRed.withValues(alpha: math.max(0.0, 1.0 - animationProgress) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(threatCenter, threatPulse, pulsePaint);
      canvas.drawCircle(threatCenter, 6, Paint()..color = AppTheme.alertRed);
    }
  }

  @override
  bool shouldRepaint(covariant _EventRadarPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.hasThreat != hasThreat ||
        oldDelegate.isCameraOnline != isCameraOnline;
  }
}
