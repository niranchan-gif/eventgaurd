import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';
import '../models/camera.dart';

class CamerasScreen extends StatelessWidget {
  const CamerasScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final activeCount = state.cameras.where((c) => !c.isEmptySlot).length;
    final standbyCount = state.cameras.where((c) => c.isEmptySlot).length;

    return Container(
      color: AppTheme.obsidianBlack,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              color: AppTheme.charcoalSurface,
              border: Border(bottom: BorderSide(color: AppTheme.hairlineBorder)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Camera Grid & Hardware Management', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                    const SizedBox(height: 4),
                    Text('$activeCount Active Hardware Sensor • $standbyCount Standby Channels Registered', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedSilver)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddCameraDialog(context),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppTheme.obsidianBlack),
                  label: Text('PROVISION CAMERA', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tacticalAmber,
                    foregroundColor: AppTheme.obsidianBlack,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Table
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.charcoalSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.hairlineBorder),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 900),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.obsidianBlack),
                      headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite, fontSize: 13),
                      dataTextStyle: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 56,
                      columns: const [
                        DataColumn(label: Text('Sensor ID')),
                        DataColumn(label: Text('Deployment Location')),
                        DataColumn(label: Text('Sector Zone')),
                        DataColumn(label: Text('Signal Quality')),
                        DataColumn(label: Text('Operational Status')),
                        DataColumn(label: Text('Controls')),
                      ],
                      rows: state.cameras.map((c) {
                        final isCam1 = c.id == 'CAM-001';
                        final isOnline = isCam1 && state.isCameraOn && state.isBackendConnected;

                        return DataRow(
                          cells: [
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.obsidianBlack,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isCam1
                                          ? (isOnline ? AppTheme.radarGreen : AppTheme.alertRed)
                                          : AppTheme.hairlineBorder,
                                    ),
                                  ),
                                  child: Icon(
                                    isCam1 ? Icons.videocam : Icons.sensors_off_outlined,
                                    size: 14,
                                    color: isCam1
                                        ? (isOnline ? AppTheme.radarGreen : AppTheme.alertRed)
                                        : AppTheme.mutedSilver,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCam1 ? '${c.id} (WEBCAM)' : c.id,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: isCam1 ? AppTheme.tacticalAmber : AppTheme.mutedSilver,
                                  ),
                                ),
                              ],
                            )),
                            DataCell(Text(
                              isCam1 ? c.location : 'Standby / Unallocated Slot',
                              style: GoogleFonts.inter(
                                color: isCam1 ? AppTheme.titaniumWhite : AppTheme.mutedSilver,
                              ),
                            )),
                            DataCell(Text(
                              c.zone,
                              style: GoogleFonts.inter(
                                color: isCam1 ? AppTheme.titaniumWhite : AppTheme.mutedSilver,
                              ),
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCam1 ? Icons.wifi : Icons.wifi_off,
                                  size: 14,
                                  color: isOnline ? AppTheme.radarGreen : AppTheme.mutedSilver,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isCam1 ? (isOnline ? 'Direct Bus 100%' : 'Muted') : 'Disconnected',
                                  style: GoogleFonts.inter(color: isCam1 ? AppTheme.titaniumWhite : AppTheme.mutedSilver),
                                ),
                              ],
                            )),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCam1
                                      ? (isOnline ? AppTheme.radarGreen.withValues(alpha: 0.18) : AppTheme.alertRed.withValues(alpha: 0.18))
                                      : AppTheme.hairlineBorder.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isCam1
                                        ? (isOnline ? AppTheme.radarGreen : AppTheme.alertRed)
                                        : AppTheme.hairlineBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isCam1
                                      ? (isOnline ? 'LIVE INGESTION' : 'MUTED / STANDBY')
                                      : 'STANDBY SLOT',
                                  style: GoogleFonts.inter(
                                    color: isCam1
                                        ? (isOnline ? AppTheme.radarGreen : AppTheme.alertRed)
                                        : AppTheme.mutedSilver,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              isCam1
                                  ? OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: state.isCameraOn ? AppTheme.alertRed : AppTheme.radarGreen,
                                        side: BorderSide(color: state.isCameraOn ? AppTheme.alertRed : AppTheme.radarGreen),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => state.toggleCameraPower(),
                                      icon: Icon(state.isCameraOn ? Icons.power_settings_new : Icons.videocam, size: 14),
                                      label: Text(
                                        state.isCameraOn ? 'MUTE' : 'ACTIVATE',
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : Text(
                                      'READY',
                                      style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCameraDialog(BuildContext context) {
    final idController = TextEditingController(text: 'CAM-SEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final locController = TextEditingController(text: 'Perimeter Checkpoint Delta');
    final zoneController = TextEditingController(text: 'Sector 02 - East Ridge');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.charcoalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.hairlineBorder, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_a_photo_outlined, color: AppTheme.tacticalAmber, size: 20),
              const SizedBox(width: 8),
              Text('Provision New Camera Unit', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Camera Unit Identifier', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: idController,
                  style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'e.g. CAM-002'),
                ),
                const SizedBox(height: 14),
                Text('Physical Location Coordinates', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: locController,
                  style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'e.g. Checkpoint Alpha'),
                ),
                const SizedBox(height: 14),
                Text('Security Sector / Tactical Zone', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: zoneController,
                  style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'e.g. Sector 02 East'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.inter(color: AppTheme.mutedSilver)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tacticalAmber,
                foregroundColor: AppTheme.obsidianBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                final newCam = Camera(
                  id: idController.text.trim(),
                  name: 'Surveillance Node',
                  location: locController.text.trim(),
                  zone: zoneController.text.trim(),
                  status: CameraStatus.online,
                  signal: 'Optimal 98%',
                  lastActive: DateTime.now(),
                  detectionModes: {'Thermal': DetectionMode.active, 'Optical': DetectionMode.active},
                );
                context.read<MockState>().addCamera(newCam);
                Navigator.pop(context);
              },
              child: Text('REGISTER NODE', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
