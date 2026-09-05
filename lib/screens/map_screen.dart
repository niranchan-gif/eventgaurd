import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.obsidianBlack,
      child: Row(
        children: [
          // Tactical Map Canvas with animated radar sweep
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _TacticalRadarPainter(animationProgress: _radarController.value),
                      size: Size.infinite,
                    );
                  },
                ),
                // Legend Overlay
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoalSurface.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.hairlineBorder),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
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
                                color: AppTheme.tacticalAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TACTICAL RADAR OVERLAY',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.tacticalAmber,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(AppTheme.radarGreen, 'Active Sensor Node (Nominal)'),
                        _buildLegendItem(AppTheme.titaniumWhite, 'Perimeter Defense Line'),
                        _buildLegendItem(AppTheme.alertRed, 'Intrusion Radar Sweep Area'),
                        _buildLegendItem(AppTheme.tacticalAmber, 'Patrol Vector Alpha'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right Control Panel
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: AppTheme.charcoalSurface,
              border: Border(left: BorderSide(color: AppTheme.hairlineBorder)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SECTOR TELEMETRY',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.tacticalAmber, fontSize: 11, letterSpacing: 0.8),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.alertRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ELEVATED',
                        style: GoogleFonts.inter(color: AppTheme.alertRed, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('North Border Sector 04', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                const SizedBox(height: 4),
                Text('MGRS: 43R EN 2819 1485  •  Elevation 840m', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.hairlineBorder),
                const SizedBox(height: 14),
                _buildZoneDetail('Operational Sensor Nodes', '8 PTZ Units'),
                _buildZoneDetail('Active Breach Signals', '2 Critical Alerts', color: AppTheme.alertRed),
                _buildZoneDetail('Radar Pulse Rate', '3.5s Sweep Period'),
                _buildZoneDetail('Network Ping Latency', '18ms (Optimal)'),
                _buildZoneDetail('Assigned Quick Reaction Team', 'Delta-9 Squad'),
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
                            color: AppTheme.tacticalAmber.withOpacity(_isDispatchHovered ? 0.4 : 0.2),
                            blurRadius: _isDispatchHovered ? 16 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tacticalAmber,
                          foregroundColor: AppTheme.obsidianBlack,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
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
          Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? AppTheme.titaniumWhite),
          ),
        ],
      ),
    );
  }
}

class _TacticalRadarPainter extends CustomPainter {
  final double animationProgress;

  _TacticalRadarPainter({required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final gridPaint = Paint()
      ..color = AppTheme.hairlineBorder.withOpacity(0.6)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 45) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 45) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Border Fence Path
    final borderPaint = Paint()
      ..color = AppTheme.titaniumWhite.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.45, size.width, size.height * 0.25);
    canvas.drawPath(path, borderPaint);

    // Online nodes with green glowing halo
    final nodePaint = Paint()..color = AppTheme.radarGreen;
    final nodeHalo = Paint()..color = AppTheme.radarGreen.withOpacity(0.25);
    
    final nodes = [
      Offset(size.width * 0.2, size.height * 0.37),
      Offset(size.width * 0.45, size.height * 0.42),
      Offset(size.width * 0.85, size.height * 0.28),
    ];

    for (var node in nodes) {
      canvas.drawCircle(node, 10, nodeHalo);
      canvas.drawCircle(node, 5, nodePaint);
    }

    // Active Threat Radar Area
    final threatCenter = Offset(size.width * 0.65, size.height * 0.35);
    final radarRadius = 80.0;

    // Concentric range rings
    final ringPaint = Paint()
      ..color = AppTheme.alertRed.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(threatCenter, radarRadius * 0.35, ringPaint);
    canvas.drawCircle(threatCenter, radarRadius * 0.7, ringPaint);
    canvas.drawCircle(threatCenter, radarRadius, ringPaint);

    // Expanding Pulse Wave
    double pulseRadius = (animationProgress * radarRadius);
    final pulsePaint = Paint()
      ..color = AppTheme.alertRed.withOpacity(math.max(0.0, 1.0 - animationProgress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(threatCenter, pulseRadius, pulsePaint);

    // Rotating Radar Sweep Line
    double angle = animationProgress * 2 * math.pi;
    final sweepEnd = Offset(
      threatCenter.dx + radarRadius * math.cos(angle),
      threatCenter.dy + radarRadius * math.sin(angle),
    );

    final sweepLinePaint = Paint()
      ..color = AppTheme.tacticalAmber.withOpacity(0.7)
      ..strokeWidth = 1.8;
    canvas.drawLine(threatCenter, sweepEnd, sweepLinePaint);

    // Center alert beacon dot
    final beaconPaint = Paint()..color = AppTheme.alertRed;
    canvas.drawCircle(threatCenter, 7, beaconPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalRadarPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
