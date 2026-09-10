import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/camera.dart';
import '../theme/app_theme.dart';

class LiveCameraFeed extends StatefulWidget {
  final Camera camera;
  final bool isModal;
  final BoxFit fit;

  const LiveCameraFeed({
    super.key,
    required this.camera,
    this.isModal = false,
    this.fit = BoxFit.cover,
  });

  @override
  State<LiveCameraFeed> createState() => _LiveCameraFeedState();
}

class _LiveCameraFeedState extends State<LiveCameraFeed> {
  Uint8List? _frameBytes;
  bool _isStreaming = false;
  bool _isOnline = false;
  int _consecutiveFailures = 0;
  late final HttpClient _httpClient;

  bool get _isPhysicalFeed =>
      widget.camera.id == 'CAM-001' ||
      widget.camera.id == 'CAM-002' ||
      widget.camera.id == 'SLOT-02';

  @override
  void initState() {
    super.initState();
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 350)
      ..idleTimeout = const Duration(seconds: 20);
    if (_isPhysicalFeed) {
      _startLiveStream();
    }
  }

  @override
  void didUpdateWidget(covariant LiveCameraFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isPhysicalFeed) {
      if (!_isStreaming) {
        _startLiveStream();
      } else if (oldWidget.camera.id != widget.camera.id) {
        _frameBytes = null; // Clear old buffer on camera swap
      }
    } else {
      _isStreaming = false;
    }
  }

  void _startLiveStream() {
    if (_isStreaming) return;
    _isStreaming = true;
    _streamLoop();
  }

  Future<void> _streamLoop() async {
    while (_isStreaming && mounted) {
      final start = DateTime.now();
      await _fetchNextFrame();
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      // Target ~30 FPS (32ms interval)
      final sleepMs = (32 - elapsed).clamp(4, 32);
      await Future.delayed(Duration(milliseconds: sleepMs));
    }
  }

  Future<void> _fetchNextFrame() async {
    if (!mounted || !_isStreaming) return;

    try {
      final String camParam = (widget.camera.id == 'CAM-002' || widget.camera.id == 'SLOT-02') ? '2' : '1';
      final url = Uri.parse('http://127.0.0.1:5000/api/frame?cam=$camParam');
      final request = await _httpClient.getUrl(url);
      final response = await request.close().timeout(const Duration(milliseconds: 400));

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        if (mounted && bytes.isNotEmpty) {
          setState(() {
            _frameBytes = bytes;
            _isOnline = true;
            _consecutiveFailures = 0;
          });
        }
      } else {
        _handleFailure();
      }
    } catch (_) {
      _handleFailure();
    }
  }

  void _handleFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures > 5 && mounted && _isOnline) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  @override
  void dispose() {
    _isStreaming = false;
    _httpClient.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhysicalCam = widget.camera.id == 'CAM-001' || widget.camera.id == 'CAM-002' || widget.camera.id == 'SLOT-02';

    if (isPhysicalCam) {
      return _buildCamFeed();
    } else {
      return _buildSimulatedFeed();
    }
  }

  Widget _buildCamFeed() {
    final bool isCam2 = widget.camera.id == 'CAM-002' || widget.camera.id == 'SLOT-02';
    final bool hasThreat = widget.camera.currentDetection.contains('CRITICAL') ||
        widget.camera.currentDetection.contains('BREACH') ||
        widget.camera.currentDetection.contains('Intrusion');

    if (_frameBytes != null && _isOnline) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.isModal ? 8 : 7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live Video Feed from Webcam / Phone
            Image.memory(
              _frameBytes!,
              fit: widget.fit,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),

            // Subtle scanline overlay for military C2 HUD aesthetic
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
            ),

            // Live hardware status indicator badge
            Positioned(
              top: widget.isModal ? 12 : 8,
              left: widget.isModal ? 12 : 8,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isModal ? 10 : 7,
                  vertical: widget.isModal ? 4 : 3,
                ),
                decoration: BoxDecoration(
                  color: hasThreat ? AppTheme.alertRed : (isCam2 ? AppTheme.tacticalAmber : AppTheme.radarGreen),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (hasThreat ? AppTheme.alertRed : (isCam2 ? AppTheme.tacticalAmber : AppTheme.radarGreen)).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasThreat ? 'BREACH ALERT' : (isCam2 ? 'LIVE • PHONE RECON' : 'LIVE • LAP CAM 01'),
                      style: GoogleFonts.inter(
                        fontSize: widget.isModal ? 11 : 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // AI Model Tag
            Positioned(
              top: widget.isModal ? 12 : 8,
              right: widget.isModal ? 12 : 8,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isModal ? 8 : 6,
                  vertical: widget.isModal ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.hairlineBorder),
                ),
                child: Text(
                  isCam2 ? 'YOLOv11 • CAM-02' : 'YOLOv11 • CAM-01',
                  style: GoogleFonts.inter(
                    color: AppTheme.tacticalAmber,
                    fontSize: widget.isModal ? 11 : 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Backend Offline / Connecting State
    return Container(
      color: AppTheme.obsidianBlack,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.charcoalSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  isCam2 ? Icons.phone_android_rounded : Icons.videocam_outlined,
                  size: 28,
                  color: AppTheme.tacticalAmber,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isCam2 ? 'CAM 02 • MOBILE RECON (PHONE)' : 'CAM 01 • LAPTOP WEBCAM',
                style: GoogleFonts.inter(
                  color: AppTheme.titaniumWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCam2 ? 'Connect phone via USB (Iriun / DroidCam) or Tethering' : 'Connecting to Python AI Backend (port 5000)...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.mutedSilver,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.tacticalAmber,
                  side: const BorderSide(color: AppTheme.tacticalAmber),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _fetchNextFrame,
                icon: const Icon(Icons.refresh, size: 14),
                label: Text(
                  'RETRY / SYNC',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedFeed() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1014),
        borderRadius: BorderRadius.circular(widget.isModal ? 8 : 7),
        border: Border.all(
          color: AppTheme.hairlineBorder.withValues(alpha: 0.6),
          style: BorderStyle.solid,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Center Empty Icon & Label
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(widget.isModal ? 16 : 10),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Icon(
                    Icons.sensors_off_outlined,
                    size: widget.isModal ? 36 : 24,
                    color: AppTheme.mutedSilver.withValues(alpha: 0.4),
                  ),
                ),
                SizedBox(height: widget.isModal ? 10 : 6),
                Text(
                  'VACANT CHANNEL',
                  style: GoogleFonts.inter(
                    fontSize: widget.isModal ? 12 : 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedSilver.withValues(alpha: 0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No Physical Sensor Configured',
                  style: GoogleFonts.inter(
                    fontSize: widget.isModal ? 10 : 8,
                    color: AppTheme.disabledGrey,
                  ),
                ),
              ],
            ),
          ),
          // Top Left Vacant Badge
          Positioned(
            top: widget.isModal ? 12 : 8,
            left: widget.isModal ? 12 : 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.hairlineBorder),
              ),
              child: Text(
                'EMPTY SLOT',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.disabledGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Top Right Slot Identifier
          Positioned(
            top: widget.isModal ? 12 : 8,
            right: widget.isModal ? 12 : 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.hairlineBorder),
              ),
              child: Text(
                widget.camera.id,
                style: GoogleFonts.inter(
                  color: AppTheme.mutedSilver,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
