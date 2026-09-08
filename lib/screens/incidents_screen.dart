import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';
import '../models/incident.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({Key? key}) : super(key: key);

  void _showLogIncidentDialog(BuildContext context) {
    final threatController = TextEditingController(text: 'Perimeter Intrusion Breach');
    final sensorController = TextEditingController(text: 'CAM-001 (Laptop Webcam)');
    final sectorController = TextEditingController(text: 'Sector 01 Command Post');
    final notesController = TextEditingController(text: 'Target observed attempting breach along northern security perimeter fence.');
    IncidentSeverity selectedSeverity = IncidentSeverity.critical;

    showDialog(
      context: context,
      builder: (ctx) {
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
                  const Icon(Icons.shield_outlined, color: AppTheme.tacticalAmber, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Log Defense Security Incident',
                    style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Threat Classification', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: threatController,
                        style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                        decoration: const InputDecoration(hintText: 'e.g. Perimeter Incursion, UAV Sighting'),
                      ),
                      const SizedBox(height: 14),

                      Text('Surveillance Sensor / Channel', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: sensorController,
                        style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                        decoration: const InputDecoration(hintText: 'e.g. CAM-001'),
                      ),
                      const SizedBox(height: 14),

                      Text('Deployment Sector Location', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: sectorController,
                        style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                        decoration: const InputDecoration(hintText: 'e.g. Sector 01'),
                      ),
                      const SizedBox(height: 14),

                      Text('Threat Escalation Severity', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.hairlineBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<IncidentSeverity>(
                            isExpanded: true,
                            value: selectedSeverity,
                            dropdownColor: AppTheme.charcoalElevated,
                            style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                            items: IncidentSeverity.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedSeverity = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Tactical Incident Intel / Operator Notes', style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                        decoration: const InputDecoration(hintText: 'Incident description and immediate actions taken...'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: GoogleFonts.inter(color: AppTheme.mutedSilver)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tacticalAmber,
                    foregroundColor: AppTheme.obsidianBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final state = context.read<MockState>();
                    final now = DateTime.now();
                    final newInc = Incident(
                      id: 'INC-${now.millisecondsSinceEpoch.toString().substring(8)}',
                      threatType: threatController.text.trim(),
                      cameraId: sensorController.text.trim(),
                      location: sectorController.text.trim(),
                      severity: selectedSeverity,
                      detectedAt: now,
                      assignedTo: state.currentUser?.name ?? 'Active Operator',
                      confidence: 96,
                      notes: notesController.text.trim(),
                      status: IncidentStatus.investigating,
                    );

                    state.addIncident(newInc);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Incident ${newInc.id} officially registered.'),
                        backgroundColor: AppTheme.charcoalElevated,
                      ),
                    );
                  },
                  child: Text('RECORD INCIDENT', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showIncidentReportDialog(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.charcoalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.hairlineBorder, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.assignment_outlined, color: AppTheme.tacticalAmber, size: 22),
              const SizedBox(width: 10),
              Text(
                'Defense Incident Report • ${incident.id}',
                style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportField('Incident Identifier', incident.id),
                _buildReportField('Threat Classification', incident.threatType),
                _buildReportField('Deployment Sector', incident.location),
                _buildReportField('Sensor / Ingestion Node', incident.cameraId),
                _buildReportField('Detection Timestamp', incident.detectedAt.toIso8601String().replaceAll('T', ' ').substring(0, 19)),
                _buildReportField('Assigned Defense Officer', incident.assignedTo),
                _buildReportField('AI Ingestion Confidence', '${incident.confidence}% Verified'),
                _buildReportField('Current Status', incident.status.name.toUpperCase()),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.hairlineBorder, height: 1),
                const SizedBox(height: 12),
                Text('Tactical Analysis & Summary:', style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Text(
                    incident.notes.isNotEmpty ? incident.notes : 'Standard optical detection triggered automated perimeter surveillance breach alarm.',
                    style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (incident.status != IncidentStatus.resolved)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.radarGreen,
                  foregroundColor: AppTheme.obsidianBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  context.read<MockState>().updateIncidentStatus(incident.id, IncidentStatus.resolved);
                  Navigator.pop(ctx);
                },
                child: Text('RESOLVE INCIDENT', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CLOSE', style: GoogleFonts.inter(color: AppTheme.mutedSilver)),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildReportField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12)),
          Text(value, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();

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
                    Text('Incident Log & Dispatch Register', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite)),
                    const SizedBox(height: 4),
                    Text('Official border defense intrusion record and active patrol dispatches', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedSilver)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showLogIncidentDialog(context),
                  icon: const Icon(Icons.add_moderator, size: 18, color: AppTheme.obsidianBlack),
                  label: Text('LOG INCIDENT', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
          // DataTable or Clean Empty State
          Expanded(
            child: state.incidents.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoalSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.hairlineBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.obsidianBlack,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.5)),
                            ),
                            child: const Icon(Icons.verified_user_outlined, color: AppTheme.tacticalAmber, size: 38),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NO LOGGED DEFENSE INCIDENTS',
                            style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Perimeter sectors are fully secure. New incidents will automatically populate when CAM-01 detects breaches or upon manual operator entry.',
                            style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.tacticalAmber,
                              foregroundColor: AppTheme.obsidianBlack,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _showLogIncidentDialog(context),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: Text('LOG TEST DRILL INCIDENT', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
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
                          constraints: const BoxConstraints(minWidth: 950),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.obsidianBlack),
                            headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite, fontSize: 13),
                            dataTextStyle: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 56,
                            columns: const [
                              DataColumn(label: Text('Incident ID')),
                              DataColumn(label: Text('Threat Classification')),
                              DataColumn(label: Text('Sensor / Node')),
                              DataColumn(label: Text('Sector Location')),
                              DataColumn(label: Text('Severity')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Operations')),
                            ],
                            rows: state.incidents.map((i) {
                              bool isCrit = i.severity == IncidentSeverity.critical;
                              Color sevColor = isCrit ? AppTheme.alertRed : AppTheme.tacticalAmber;
                              bool isResolved = i.status == IncidentStatus.resolved;

                              return DataRow(
                                cells: [
                                  DataCell(Text(i.id, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.tacticalAmber))),
                                  DataCell(Text(i.threatType)),
                                  DataCell(Text(i.cameraId)),
                                  DataCell(Text(i.location)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: sevColor.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: sevColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        i.severity.name.toUpperCase(),
                                        style: GoogleFonts.inter(color: sevColor, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isResolved ? AppTheme.radarGreen.withValues(alpha: 0.2) : AppTheme.tacticalAmber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        i.status.name.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          color: isResolved ? AppTheme.radarGreen : AppTheme.tacticalAmber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isResolved)
                                        ElevatedButton(
                                          onPressed: () => context.read<MockState>().updateIncidentStatus(i.id, IncidentStatus.resolved),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.radarGreen,
                                            foregroundColor: AppTheme.obsidianBlack,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            minimumSize: Size.zero,
                                          ),
                                          child: Text('RESOLVE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _showIncidentReportDialog(context, i),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.titaniumWhite,
                                          side: const BorderSide(color: AppTheme.hairlineBorder),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          minimumSize: Size.zero,
                                        ),
                                        child: Text('VIEW REPORT', style: GoogleFonts.inter(fontSize: 11)),
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
}
