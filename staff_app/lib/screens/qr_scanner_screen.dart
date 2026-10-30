import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late AnimationController _animController;
  late Animation<double> _laserAnimation;
  bool _hasDetected = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasDetected) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        try {
          final data = jsonDecode(raw);
          if (data is Map<String, dynamic>) {
            _hasDetected = true;
            Navigator.pop(context, data);
            return;
          }
        } catch (_) {
          // Check if string contains standard colon separated format
        }
      }
    }
  }

  void _showManualSimulationDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141926),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Simulate QR Scan (Emulator Mode)',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste the pairing JSON copied from the HQ screen, or choose a default setup:',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: '{"hq_ip": "192.168.0.10", "hq_port": "8765", ...}',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0C101A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, {
                'hq_ip': '192.168.0.10',
                'hq_port': '8765',
                'token': 'EVENTGUARD_DEMO_2026',
                'staff_id': 'STAFF-001',
                'team_id': 'SECURITY-A',
                'zone': 'Zone A (Main Concourse)',
              });
            },
            child: const Text('Use Default Local IP'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            onPressed: () {
              final raw = textController.text.trim();
              if (raw.isNotEmpty) {
                try {
                  final data = jsonDecode(raw);
                  if (data is Map<String, dynamic>) {
                    Navigator.pop(ctx);
                    Navigator.pop(context, data);
                    return;
                  }
                } catch (_) {}
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Live Scanner
          MobileScanner(
            controller: _cameraController,
            onDetect: _onBarcodeDetected,
          ),

          // Sci-Fi Dark Vignette Overlay with Center Transparent Cutout
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ScannerOverlayPainter(),
          ),

          // Animated Laser Scan Line & Viewfinder Box
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.6), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner Reticles
                  _buildCornerReticle(Alignment.topLeft),
                  _buildCornerReticle(Alignment.topRight),
                  _buildCornerReticle(Alignment.bottomLeft),
                  _buildCornerReticle(Alignment.bottomRight),

                  // Animated Horizontal Laser Line
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      return Align(
                        alignment: Alignment(0, (_laserAnimation.value * 2) - 1.0),
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SCAN HQ PAIRING CODE',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isTorchOn ? const Color(0xFFEAB308) : Colors.white,
                  ),
                  onPressed: () async {
                    await _cameraController.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
              ],
            ),
          ),

          // Bottom Controls & Fallback Simulator
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  'Point camera at the QR code displayed on the EventGuard HQ Console',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF141926).withValues(alpha: 0.85),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.keyboard_alt_outlined, color: Color(0xFF4F46E5), size: 18),
                      label: Text(
                        'Simulate / Paste Code',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _showManualSimulationDialog,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF141926).withValues(alpha: 0.85),
                      ),
                      icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
                      onPressed: () => _cameraController.switchCamera(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerReticle(Alignment alignment) {
    const double length = 20.0;
    const double thickness = 3.5;
    const Color color = Color(0xFF10B981);

    return Align(
      alignment: alignment,
      child: Container(
        width: length,
        height: length,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            bottom: alignment.y > 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            left: alignment.x < 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            right: alignment.x > 0 ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    const cutoutSize = 260.0;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2;

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
          const Radius.circular(16),
        ),
      );

    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
