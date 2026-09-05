import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkOlive,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Configuration & Preferences', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.cream)),
            const SizedBox(height: 4),
            Text('Manage border defense telemetry, AI detection thresholds, and station security', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            _buildSettingsSection('OPERATIONAL ENVIRONMENT', [
              _buildSwitchTile('Tactical Dark High-Contrast Mode', true),
              _buildListTile('Language Protocol', 'English (Military Nomenclature)'),
              _buildListTile('Geographic Coordinates Standard', 'WGS 84 / MGRS'),
            ]),
            const SizedBox(height: 20),
            _buildSettingsSection('AI INTRUSION SENSITIVITY', [
              _buildSliderTile('Human Detection Sensitivity Threshold', 0.85),
              _buildListTile('False Alarm Suppression Filter', 'Aggressive (AI Multi-frame verification)'),
              _buildListTile('Video Feed Sync Latency Target', '< 150ms'),
            ]),
            const SizedBox(height: 20),
            _buildSettingsSection('SECURITY & ESCALATION', [
              _buildSwitchTile('Audible Siren upon Level 1 Breach', true),
              _buildSwitchTile('Automated Patrol Notification Dispatch', true),
              _buildSwitchTile('Biometric Operator Confirmation', false),
            ]),
            const SizedBox(height: 20),
            _buildSettingsSection('HARDWARE & TELEMETRY', [
              _buildListTile('Terminal Deployment State', 'Station 04 • Active Secured Encrypted Link'),
              _buildListTile('Build Version', 'BorderGuard Tactical Suite v2.4.1 (SIH Edition)'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.deepGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.orange, fontSize: 11, letterSpacing: 0.8),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: (v) {},
      activeThumbColor: AppTheme.orange,
      activeTrackColor: AppTheme.orange.withOpacity(0.4),
    );
  }

  Widget _buildListTile(String title, String subtitle) {
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.cream, size: 18),
    );
  }

  Widget _buildSliderTile(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w500)),
              Text('${(value * 100).toInt()}%', style: GoogleFonts.inter(color: AppTheme.orange, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.orange,
              thumbColor: AppTheme.orange,
              inactiveTrackColor: AppTheme.darkOlive,
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              onChanged: (v) {},
            ),
          ),
        ],
      ),
    );
  }
}
