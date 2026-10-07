import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../mock/mock_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();

    return Container(
      color: AppTheme.obsidianBlack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Configuration & Preferences',
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.titaniumWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage border management telemetry, AI detection sensitivity, escalation protocols, and telemetry feeds',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedSilver),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.mutedSilver,
                        side: const BorderSide(color: AppTheme.hairlineBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        state.resetSettingsToDefault();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preferences restored to event factory defaults.'),
                            backgroundColor: AppTheme.charcoalElevated,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: Text('RESET DEFAULTS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.uiAmber,
                        foregroundColor: AppTheme.obsidianBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppTheme.radarGreen, size: 18),
                                const SizedBox(width: 8),
                                Text('Configuration active & synced with Sector 01 Node.', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            backgroundColor: AppTheme.charcoalElevated,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: Text('SAVE CONFIG', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSettingsSection('OPERATIONAL ENVIRONMENT', [
              _buildSwitchTile(
                title: 'Event High-Contrast Dark Mode',
                subtitle: 'Optimized OLED contrast for low-light HQ command center stations',
                value: state.highContrastMode,
                onChanged: (v) => state.toggleHighContrast(v),
              ),
              _buildActionTile(
                context: context,
                title: 'Language Protocol',
                subtitle: state.languageProtocol,
                icon: Icons.language,
                onTap: () => _showSelectionDialog(
                  context: context,
                  title: 'Select Operational Language Protocol',
                  currentValue: state.languageProtocol,
                  options: [
                    'English (Event Nomenclature)',
                    'English (Standard Civil Management)',
                    'Hindi (Armed Forces Standard)',
                    'NATO Multilingual Standard',
                  ],
                  onSelected: (val) => state.setLanguageProtocol(val),
                ),
              ),
              _buildActionTile(
                context: context,
                title: 'Geographic Coordinates Standard',
                subtitle: state.coordinatesStandard,
                icon: Icons.location_searching,
                onTap: () => _showSelectionDialog(
                  context: context,
                  title: 'Select Geographic Coordinates Format',
                  currentValue: state.coordinatesStandard,
                  options: [
                    'WGS 84 / MGRS (Event Grid Reference)',
                    'Universal Transverse Mercator (UTM)',
                    'Decimal Degrees (Lat / Long GPS)',
                    'Degrees Minutes Seconds (DMS)',
                  ],
                  onSelected: (val) => state.setCoordinatesStandard(val),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSettingsSection('AI INCIDENT SENSITIVITY & COMPUTER VISION', [
              _buildSliderTile(
                title: 'Human Detection Sensitivity Threshold',
                subtitle: 'Controls YOLO confidence threshold for raising automated perimeter alerts',
                value: state.detectionSensitivity,
                onChanged: (v) => state.setDetectionSensitivity(v),
              ),
              _buildActionTile(
                context: context,
                title: 'False Alarm Suppression Filter',
                subtitle: state.falseAlarmFilter,
                icon: Icons.filter_alt_outlined,
                onTap: () => _showSelectionDialog(
                  context: context,
                  title: 'Configure False Alarm Suppression',
                  currentValue: state.falseAlarmFilter,
                  options: [
                    'Aggressive (AI Multi-frame verification)',
                    'Balanced (Standard 3-frame confirmation)',
                    'Sensitive (Fast-trigger single frame alert)',
                  ],
                  onSelected: (val) => state.setFalseAlarmFilter(val),
                ),
              ),
              _buildInfoTile('Live Video Feed Latency Target', '< 150ms Direct Hardware Bus • CAM-01 Active'),
            ]),
            const SizedBox(height: 20),

            _buildSettingsSection('SECURITY & ESCALATION PROTOCOLS', [
              _buildSwitchTile(
                title: 'Audible Siren upon Level 1 Perimeter Breach',
                subtitle: 'Trigger hardware audio alarm when incident is detected in Sector 01',
                value: state.audibleSiren,
                onChanged: (v) => state.toggleAudibleSiren(v),
              ),
              _buildSwitchTile(
                title: 'Automated Rapid Patrol Notification Dispatch',
                subtitle: 'Automatically notify Quick Reaction Team when critical breach flag triggers',
                value: state.autoPatrolDispatch,
                onChanged: (v) => state.toggleAutoPatrolDispatch(v),
              ),
              _buildSwitchTile(
                title: 'Biometric / Secondary Operator Confirmation',
                subtitle: 'Require secondary confirmation before acknowledging critical breaches',
                value: state.biometricConfirmation,
                onChanged: (v) => state.toggleBiometric(v),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSettingsSection('HARDWARE TERMINAL & TELEMETRY', [
              _buildInfoTile('Active Physical Sensor', 'CAM-01 (Laptop Webcam) • 640x480 Direct Ingestion'),
              _buildInfoTile('Terminal Deployment State', 'Station 01 • Active Encrypted TLS Link'),
              _buildInfoTile('Build Version', 'EventGuard AI Event Suite v2.4.1 (SIH Special Edition)'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.hairlineBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.uiAmber, fontSize: 11, letterSpacing: 0.8),
            ),
          ),
          const Divider(height: 1, color: AppTheme.hairlineBorder),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.uiAmber,
      activeTrackColor: AppTheme.uiAmber.withValues(alpha: 0.4),
      inactiveThumbColor: AppTheme.mutedSilver,
      inactiveTrackColor: AppTheme.obsidianBlack,
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.uiAmber, size: 20),
      title: Text(title, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedSilver, size: 20),
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
      trailing: const Icon(Icons.lock_outline, color: AppTheme.mutedSilver, size: 16),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianBlack,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.uiAmber),
                ),
                child: Text(
                  '${(value * 100).toInt()}% CONFIDENCE',
                  style: GoogleFonts.inter(color: AppTheme.uiAmber, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.uiAmber,
              thumbColor: AppTheme.uiAmber,
              inactiveTrackColor: AppTheme.obsidianBlack,
              overlayColor: AppTheme.uiAmber.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.50,
              max: 1.0,
              divisions: 50,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectionDialog({
    required BuildContext context,
    required String title,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.charcoalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.hairlineBorder, width: 1.5),
          ),
          title: Text(title, style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final isSelected = opt == currentValue;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: isSelected ? AppTheme.obsidianBlack : null,
                title: Text(opt, style: GoogleFonts.inter(color: isSelected ? AppTheme.uiAmber : AppTheme.titaniumWhite, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check, color: AppTheme.uiAmber, size: 18) : null,
                onTap: () {
                  onSelected(opt);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CLOSE', style: GoogleFonts.inter(color: AppTheme.mutedSilver)),
            ),
          ],
        );
      },
    );
  }
}
