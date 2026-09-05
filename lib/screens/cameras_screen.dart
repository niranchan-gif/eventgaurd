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
    return Container(
      color: AppTheme.darkOlive,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.deepGreen,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Camera Grid Management', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.cream)),
                    const SizedBox(height: 2),
                    Text('${state.cameras.length} Active PTZ & Thermal units connected', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddCameraDialog(context),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppTheme.darkOlive),
                  label: Text('PROVISION CAMERA', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: AppTheme.darkOlive,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  color: AppTheme.deepGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 850),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppTheme.darkOlive),
                      headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.cream, fontSize: 13),
                      dataTextStyle: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('Unit ID')),
                        DataColumn(label: Text('Deployment Location')),
                        DataColumn(label: Text('Sector Zone')),
                        DataColumn(label: Text('Signal Quality')),
                        DataColumn(label: Text('Operational Status')),
                        DataColumn(label: Text('Controls')),
                      ],
                      rows: state.cameras.map((c) {
                        bool isOnline = c.status == CameraStatus.online;
                        return DataRow(
                          cells: [
                            DataCell(Text(c.id, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.orange))),
                            DataCell(Text(c.location)),
                            DataCell(Text(c.zone)),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi, size: 16, color: AppTheme.safe),
                                const SizedBox(width: 6),
                                Text(c.signal),
                              ],
                            )),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isOnline ? AppTheme.safe.withOpacity(0.2) : AppTheme.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  c.status.name.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: isOnline ? AppTheme.safe : AppTheme.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.cream, size: 18),
                                  splashRadius: 16,
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.orange, size: 18),
                                  splashRadius: 16,
                                  onPressed: () => context.read<MockState>().deleteCamera(c.id),
                                ),
                              ],
                            )),
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
          backgroundColor: AppTheme.deepGreen,
          title: Text('Provision New Camera Unit', style: GoogleFonts.inter(color: AppTheme.cream, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  style: GoogleFonts.inter(color: AppTheme.cream),
                  decoration: const InputDecoration(labelText: 'Camera Unit Identifier'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: locController,
                  style: GoogleFonts.inter(color: AppTheme.cream),
                  decoration: const InputDecoration(labelText: 'Physical Location'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: zoneController,
                  style: GoogleFonts.inter(color: AppTheme.cream),
                  decoration: const InputDecoration(labelText: 'Security Sector / Zone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.inter(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: AppTheme.darkOlive,
              ),
              onPressed: () {
                final newCam = Camera(
                  id: idController.text,
                  name: 'Surveillance Node',
                  location: locController.text,
                  zone: zoneController.text,
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
