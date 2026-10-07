import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';
import '../models/camera.dart';
import '../widgets/live_camera_feed.dart';

class LiveSurveillanceScreen extends StatefulWidget {
  const LiveSurveillanceScreen({Key? key}) : super(key: key);

  @override
  State<LiveSurveillanceScreen> createState() => _LiveSurveillanceScreenState();
}

class _LiveSurveillanceScreenState extends State<LiveSurveillanceScreen> {
  String _selectedZone = 'All Zones';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final query = _searchController.text.trim().toLowerCase();

    final filteredCameras = state.cameras.where((c) {
      if (_selectedZone != 'All Zones' && !c.zone.toLowerCase().contains(_selectedZone.toLowerCase())) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchId = c.id.toLowerCase().contains(query);
        final matchName = c.name.toLowerCase().contains(query);
        final matchLoc = c.location.toLowerCase().contains(query);
        final matchZone = c.zone.toLowerCase().contains(query);
        return matchId || matchName || matchLoc || matchZone;
      }
      return true;
    }).toList();

    return Container(
      color: AppTheme.obsidianBlack,
      child: Column(
        children: [
          // Filter & Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.charcoalSurface,
              border: Border(bottom: BorderSide(color: AppTheme.hairlineBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search camera node ID, sector, coordinates...',
                        hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.uiAmber, size: 18),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: AppTheme.mutedSilver),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppTheme.obsidianBlack,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.hairlineBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.hairlineBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.uiAmber, width: 1.5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  height: 42,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedZone,
                      dropdownColor: AppTheme.charcoalElevated,
                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13, fontWeight: FontWeight.bold),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.uiAmber),
                      items: [
                        'All Zones',
                        'Sector 01',
                        'Sector 02',
                        'Sector 03',
                        'Sector 04',
                        'Sector 05',
                        'Sector 06',
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedZone = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isCameraOn ? AppTheme.alertRed.withValues(alpha: 0.18) : AppTheme.radarGreen.withValues(alpha: 0.2),
                    foregroundColor: state.isCameraOn ? AppTheme.alertRed : AppTheme.radarGreen,
                    side: BorderSide(color: state.isCameraOn ? AppTheme.alertRed : AppTheme.radarGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => state.toggleCameraPower(),
                  icon: Icon(state.isCameraOn ? Icons.power_settings_new : Icons.videocam, size: 16),
                  label: Text(
                    state.isCameraOn ? 'MUTE CAM 01' : 'ACTIVATE CAM 01',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // CCTV Grid with Responsive Columns
          Expanded(
            child: filteredCameras.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.charcoalSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.hairlineBorder),
                          ),
                          child: const Icon(Icons.videocam_off_outlined, size: 40, color: AppTheme.mutedSilver),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Camera Nodes Found in $_selectedZone',
                          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try clearing your search query or selecting "All Zones".',
                          style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedZone = 'All Zones';
                              _searchController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.uiAmber,
                            foregroundColor: AppTheme.obsidianBlack,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('RESET FILTERS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int cols = 3;
                      if (constraints.maxWidth < 800) {
                        cols = 1;
                      } else if (constraints.maxWidth < 1250) {
                        cols = 2;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 16 / 9.8,
                        ),
                        itemCount: filteredCameras.length,
                        itemBuilder: (context, index) {
                          return _EventCameraCard(
                            camera: filteredCameras[index],
                            onTap: () => _showCameraModal(context, filteredCameras[index]),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCameraModal(BuildContext context, Camera camera) {
    final isCam1 = camera.id == 'CAM-001';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentState = context.watch<MockState>();
            final currentMode = currentState.activeAiMode;

            return AlertDialog(
              backgroundColor: AppTheme.charcoalSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.hairlineBorder, width: 1.5),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              title: Row(
                children: [
                  const Icon(Icons.sensors, color: AppTheme.uiAmber, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Monitoring Feed Inspector: ${camera.id}',
                    style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const Spacer(),
                  if (isCam1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentState.isBackendConnected ? AppTheme.radarGreen.withValues(alpha: 0.18) : AppTheme.alertRed.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: currentState.isBackendConnected ? AppTheme.radarGreen : AppTheme.alertRed),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: currentState.isBackendConnected ? AppTheme.radarGreen : AppTheme.alertRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentState.isBackendConnected ? 'WEBCAM ACTIVE • ${currentState.cam1Fps.toStringAsFixed(1)} FPS' : 'BACKEND OFFLINE',
                            style: GoogleFonts.inter(
                              color: currentState.isBackendConnected ? AppTheme.radarGreen : AppTheme.alertRed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              content: SizedBox(
                width: 860,
                height: 480,
                child: Row(
                  children: [
                    // Video Feed Viewport
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianBlack,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.hairlineBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LiveCameraFeed(camera: camera, isModal: true),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Controls & Telemetry
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianBlack,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.hairlineBorder),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCam1) ...[
                                Text('AI DETECTION ENGINE MODE', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.uiAmber, fontSize: 11, letterSpacing: 0.6)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _buildModeButton(context, 'ALL ENGINES', 'all', currentMode),
                                    _buildModeButton(context, 'HUMAN', 'person', currentMode),
                                    _buildModeButton(context, 'VEHICLE', 'vehicle', currentMode),
                                    _buildModeButton(context, 'VIRTUAL FENCE', 'fence', currentMode),
                                    _buildModeButton(context, 'FACE DETECT', 'face', currentMode),
                                    _buildModeButton(context, 'ANPR', 'anpr', currentMode),
                                  ],
                                ),
                                const Divider(color: AppTheme.hairlineBorder, height: 24),
                                Text('LIVE AI INFERENCE TELEMETRY', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.uiAmber, fontSize: 11, letterSpacing: 0.6)),
                                const SizedBox(height: 10),
                                _buildModalRow('Persons Tracked', '${currentState.cam1Counts['person'] ?? 0}'),
                                _buildModalRow('Vehicles Tracked', '${currentState.cam1Counts['vehicle'] ?? 0}'),
                                _buildModalRow('Animals Tracked', '${currentState.cam1Counts['animal'] ?? 0}'),
                                _buildModalRow('Faces Tracked', '${currentState.cam1Counts['face'] ?? 0}'),
                                _buildModalRow(
                                  'Perimeter Breach',
                                  currentState.intrusionDetected ? 'CRITICAL ALERT' : 'SECURE (CLEAR)',
                                  isAlert: currentState.intrusionDetected,
                                ),
                                const Divider(color: AppTheme.hairlineBorder, height: 24),
                              ],
                              Text('HARDWARE SPECIFICATIONS', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.uiAmber, fontSize: 11, letterSpacing: 0.6)),
                              const SizedBox(height: 10),
                              _buildModalRow('Sensor Location', camera.location),
                              _buildModalRow('Event Sector', camera.zone),
                              _buildModalRow('Signal Telemetry', camera.signal),
                              _buildModalRow('Operational Status', camera.status.name.toUpperCase()),
                              _buildModalRow('Active Threat State', camera.currentDetection),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.uiAmber,
                    foregroundColor: AppTheme.obsidianBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE INSPECTOR', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModeButton(BuildContext context, String label, String modeKey, String currentMode) {
    final bool isSelected = currentMode.toLowerCase() == modeKey.toLowerCase();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.read<MockState>().setAiMode(modeKey);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.uiAmber : AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.uiAmber : AppTheme.hairlineBorder,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? AppTheme.obsidianBlack : AppTheme.titaniumWhite,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12)),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isAlert ? AppTheme.alertRed : AppTheme.titaniumWhite,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCameraCard extends StatefulWidget {
  final Camera camera;
  final VoidCallback onTap;

  const _EventCameraCard({Key? key, required this.camera, required this.onTap}) : super(key: key);

  @override
  State<_EventCameraCard> createState() => _EventCameraCardState();
}

class _EventCameraCardState extends State<_EventCameraCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final camera = widget.camera;
    final bool hasThreat = camera.currentDetection != 'No Threat' && camera.currentDetection != 'Offline';
    final bool isOnline = camera.status == CameraStatus.online;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: AppTheme.charcoalSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasThreat
                    ? AppTheme.alertRed
                    : (_isHovered ? AppTheme.uiAmber : AppTheme.hairlineBorder),
                width: hasThreat || _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasThreat
                      ? AppTheme.alertRed.withValues(alpha: 0.25)
                      : (_isHovered ? AppTheme.uiAmber.withValues(alpha: 0.15) : Colors.black45),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live camera feed or standby feed
                LiveCameraFeed(camera: camera),

                // Top Floating Badges
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Node ID & Sector badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianBlack.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.hairlineBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              camera.id,
                              style: GoogleFonts.inter(
                                color: AppTheme.uiAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${camera.zone}',
                              style: GoogleFonts.inter(
                                color: AppTheme.mutedSilver,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianBlack.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOnline ? AppTheme.radarGreen : AppTheme.mutedSilver.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isOnline ? AppTheme.radarGreen : AppTheme.mutedSilver,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOnline ? 'ONLINE' : 'STANDBY',
                              style: GoogleFonts.inter(
                                color: isOnline ? AppTheme.radarGreen : AppTheme.mutedSilver,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Floating Info Banner
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.obsidianBlack.withValues(alpha: 0.85),
                          AppTheme.obsidianBlack.withValues(alpha: 0.96),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                camera.location,
                                style: GoogleFonts.inter(
                                  color: AppTheme.titaniumWhite,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasThreat
                                          ? AppTheme.alertRed.withValues(alpha: 0.2)
                                          : AppTheme.radarGreen.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: hasThreat ? AppTheme.alertRed : AppTheme.radarGreen,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      camera.currentDetection.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: hasThreat ? AppTheme.alertRed : AppTheme.radarGreen,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    camera.signal,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.mutedSilver,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.charcoalSurface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.hairlineBorder),
                          ),
                          child: const Icon(Icons.fullscreen, color: AppTheme.uiAmber, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
