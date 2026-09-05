import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';
import '../models/incident.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    return Container(
      color: AppTheme.darkOlive,
      child: Column(
        children: [
          // Header Bar
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
                    Text('Incident Log & Dispatch', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.cream)),
                    const SizedBox(height: 2),
                    Text('Official border security intrusion register', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.security, size: 18, color: AppTheme.darkOlive),
                  label: Text('LOG INCIDENT', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: AppTheme.darkOlive,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable DataTable (Both Horizontal and Vertical to prevent RenderFlex overflow)
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
                    constraints: const BoxConstraints(minWidth: 900),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppTheme.darkOlive),
                      headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.cream, fontSize: 13),
                      dataTextStyle: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13),
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
                        Color sevColor = isCrit ? AppTheme.orange : AppTheme.cream;
                        bool isResolved = i.status == IncidentStatus.resolved;

                        return DataRow(
                          cells: [
                            DataCell(Text(i.id, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.orange))),
                            DataCell(Text(i.threatType)),
                            DataCell(Text(i.cameraId)),
                            DataCell(Text(i.location)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCrit ? AppTheme.orange.withOpacity(0.2) : AppTheme.darkOlive,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isCrit ? AppTheme.orange : AppTheme.borderSubtle),
                                ),
                                child: Text(
                                  i.severity.name.toUpperCase(),
                                  style: GoogleFonts.inter(color: sevColor, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isResolved ? AppTheme.safe.withOpacity(0.2) : AppTheme.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  i.status.name.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: isResolved ? AppTheme.safe : AppTheme.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
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
                                      backgroundColor: AppTheme.safe,
                                      foregroundColor: AppTheme.darkOlive,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text('RESOLVE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.cream,
                                    side: const BorderSide(color: AppTheme.border),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
