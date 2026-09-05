import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';
import '../models/alert.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final filteredAlerts = state.alerts.where((a) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Critical') return a.severity == AlertSeverity.critical;
      if (_selectedFilter == 'Active') return a.status == AlertStatus.active;
      if (_selectedFilter == 'Resolved') return a.status == AlertStatus.resolved;
      return true;
    }).toList();

    return Container(
      color: AppTheme.darkOlive,
      child: Column(
        children: [
          // Filter & Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.deepGreen,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('Critical'),
                        _buildFilterChip('Active'),
                        _buildFilterChip('Resolved'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 260,
                  height: 40,
                  child: TextField(
                    style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search alert ID, sector...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textDisabled, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.cream),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: AppTheme.darkOlive,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.border)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alert List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredAlerts.length,
              itemBuilder: (context, index) {
                final alert = filteredAlerts[index];
                bool isCritical = alert.severity == AlertSeverity.critical;
                bool isActive = alert.status == AlertStatus.active;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.deepGreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCritical && isActive ? AppTheme.orange : AppTheme.border,
                      width: isCritical && isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.darkOlive,
                          shape: BoxShape.circle,
                          border: Border.all(color: isCritical ? AppTheme.orange : AppTheme.cream),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: isCritical ? AppTheme.orange : AppTheme.cream,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppTheme.orange.withOpacity(0.2) : AppTheme.safe.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isActive ? AppTheme.orange : AppTheme.safe),
                                  ),
                                  child: Text(
                                    alert.status.name.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: isActive ? AppTheme.orange : AppTheme.safe,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  alert.id,
                                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              alert.title,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.cream),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Camera: ${alert.cameraId}  •  Sector: ${alert.location}  •  Detected: ${alert.detectedAt.toString().substring(0, 16)}',
                              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (isActive) ...[
                        OutlinedButton(
                          onPressed: () => context.read<MockState>().acknowledgeAlert(alert.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.cream,
                            side: const BorderSide(color: AppTheme.cream),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: Text('ACKNOWLEDGE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => context.read<MockState>().resolveAlert(alert.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.orange,
                            foregroundColor: AppTheme.darkOlive,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: Text('RESOLVE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.darkOlive,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: AppTheme.safe),
                              const SizedBox(width: 6),
                              Text('RESOLVED', style: GoogleFonts.inter(color: AppTheme.safe, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.orange : AppTheme.darkOlive,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppTheme.orange : AppTheme.border),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? AppTheme.darkOlive : AppTheme.cream,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
