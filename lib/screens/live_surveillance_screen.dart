import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';
import '../models/camera.dart';

class LiveSurveillanceScreen extends StatefulWidget {
  const LiveSurveillanceScreen({Key? key}) : super(key: key);

  @override
  State<LiveSurveillanceScreen> createState() => _LiveSurveillanceScreenState();
}

class _LiveSurveillanceScreenState extends State<LiveSurveillanceScreen> {
  String _selectedZone = 'All Zones';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final cameras = state.cameras;

    return Container(
      color: AppTheme.darkOlive,
      child: Column(
        children: [
          // Filter & Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.deepGreen,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search camera node ID, sector, coordinates...',
                        hintStyle: GoogleFonts.inter(color: AppTheme.textDisabled, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.cream, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: AppTheme.darkOlive,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.border)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkOlive,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  height: 40,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedZone,
                      dropdownColor: AppTheme.darkOlive,
                      style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.bold),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.orange),
                      items: ['All Zones', 'North Sector', 'East Ridge', 'West Basin'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedZone = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.grid_view, color: AppTheme.orange),
                  splashRadius: 18,
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: AppTheme.cream),
                  splashRadius: 18,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // CCTV Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 16 / 10,
              ),
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                return _buildCCTVFeed(context, cameras[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCCTVFeed(BuildContext context, Camera camera) {
    bool isOnline = camera.status == CameraStatus.online;
    bool hasThreat = camera.currentDetection != 'No Threat' && camera.currentDetection != 'Offline';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showCameraModal(context, camera),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkOlive,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasThreat ? AppTheme.orange : AppTheme.border,
            width: hasThreat ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Icon(
                Icons.videocam_outlined,
                size: 54,
                color: isOnline ? AppTheme.cream.withOpacity(0.2) : AppTheme.cream.withOpacity(0.08),
              ),
            ),
            // Live Status Tag
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnline ? (hasThreat ? AppTheme.orange : AppTheme.safe) : Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? (hasThreat ? 'ALERT' : 'LIVE') : 'OFFLINE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: hasThreat ? AppTheme.darkOlive : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Node ID
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  camera.id,
                  style: GoogleFonts.inter(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
            // Bottom Info Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            camera.location,
                            style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            camera.currentDetection,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: hasThreat ? AppTheme.orange : AppTheme.safe,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: AppTheme.cream, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraModal(BuildContext context, Camera camera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.border)),
        title: Text('Surveillance Feed Detail: ${camera.id}', style: GoogleFonts.inter(color: AppTheme.cream, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 750,
          height: 420,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkOlive,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.videocam_outlined, size: 80, color: AppTheme.cream),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CAMERA SPECIFICATIONS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.orange, fontSize: 12)),
                    const SizedBox(height: 12),
                    _buildModalRow('Location', camera.location),
                    _buildModalRow('Sector Zone', camera.zone),
                    _buildModalRow('Signal Strength', camera.signal),
                    _buildModalRow('Status', camera.status.name.toUpperCase()),
                    const Divider(color: AppTheme.border, height: 24),
                    Text('ACTIVE AI DETECTION CHANNELS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.orange, fontSize: 12)),
                    const SizedBox(height: 12),
                    ...camera.detectionModes.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 12)),
                          Text('ACTIVE', style: GoogleFonts.inter(color: AppTheme.safe, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: AppTheme.darkOlive,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE INSPECTOR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
          Text(value, style: GoogleFonts.inter(color: AppTheme.cream, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
