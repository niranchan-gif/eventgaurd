import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.0.10');
  final TextEditingController _portController = TextEditingController(text: '8765');
  final TextEditingController _tokenController = TextEditingController(text: 'EVENTGUARD_DEMO_2026');
  final TextEditingController _staffIdController = TextEditingController(text: 'STAFF-001');

  String _selectedTeam = 'SECURITY-A';
  String _selectedZone = 'Zone A (Main Concourse)';

  // Emergency Dispatch Form State
  String _deployTarget = 'ALL';
  String _deployPriority = 'CRITICAL';
  final TextEditingController _deployTitleController = TextEditingController(text: 'Gate A Crowd Congestion Surge');
  final TextEditingController _deployLocationController = TextEditingController(text: 'Main Entrance Concourse');
  final TextEditingController _deployMessageController = TextEditingController(
    text: 'Deploy immediately to Gate A concourse. Form bilateral crowd flow lanes to relieve turnstile bottleneck.',
  );
  bool _isDispatching = false;

  final List<String> _teamOptions = const [
    'SECURITY-A',
    'CROWD-CONTROL',
    'FIRST-RESPONDERS',
    'GATE-MANAGEMENT',
    'VOLUNTEER-STEWARDS',
  ];

  final List<String> _zoneOptions = const [
    'Zone A (Main Concourse)',
    'Zone B (North Plaza)',
    'Zone C (Flow Gates)',
    'Zone D (Stage Perimeter)',
  ];

  @override
  void initState() {
    super.initState();
    _autoDetectLocalIp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MockState>().refreshStaffRoster();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    _staffIdController.dispose();
    _deployTitleController.dispose();
    _deployLocationController.dispose();
    _deployMessageController.dispose();
    super.dispose();
  }

  Future<void> _autoDetectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            if (mounted) {
              setState(() {
                _ipController.text = addr.address;
              });
            }
            return;
          }
        }
      }
    } catch (_) {}
  }

  String _generateQrPayload() {
    final payload = {
      'app': 'EVENTGUARD_STAFF',
      'hq_ip': _ipController.text.trim(),
      'hq_port': _portController.text.trim(),
      'token': _tokenController.text.trim(),
      'staff_id': _staffIdController.text.trim(),
      'team_id': _selectedTeam,
      'zone': _selectedZone,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(payload);
  }

  Future<void> _handleEmergencyDispatch() async {
    final state = context.read<MockState>();
    setState(() => _isDispatching = true);

    final success = await state.sendDeployCommand(
      teamId: _deployTarget == 'ALL' ? 'ALL' : _deployTarget,
      staffId: _deployTarget.startsWith('STAFF-') ? _deployTarget : null,
      title: _deployTitleController.text.trim(),
      description: _deployMessageController.text.trim(),
      priority: _deployPriority,
      locationName: _deployLocationController.text.trim(),
    );

    if (mounted) {
      setState(() => _isDispatching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              Icon(success ? Icons.notifications_active_rounded : Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'EMERGENCY DISPATCH TRIGGERED -> Mobile Alarm & Vibration Broadcast Sent!'
                      : 'Dispatch sent via fallback WebSocket queue.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final connectedStaff = state.connectedStaffList;
    final qrPayload = _generateQrPayload();

    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            _buildPageHeader(state),
            const SizedBox(height: 24),

            // Top Row: QR Code Generator & Pairing Configuration
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: QR Code Display Card
                Expanded(
                  flex: 5,
                  child: _buildQrCodeCard(qrPayload),
                ),
                const SizedBox(width: 24),
                // Right: Staff Allocation & Network Settings Card
                Expanded(
                  flex: 6,
                  child: _buildAllocationConfigCard(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Section: Connected Stewards Roster & Emergency Dispatch Command
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Live Connected Staff Roster
                Expanded(
                  flex: 5,
                  child: _buildConnectedStaffRoster(connectedStaff),
                ),
                const SizedBox(width: 24),
                // Right: Emergency Deployment Console
                Expanded(
                  flex: 6,
                  child: _buildEmergencyDispatchConsole(connectedStaff),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(MockState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.uiAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.uiAmber.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.uiAmber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Allocation & Mobile QR Pairing',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate instant pairing QR codes for Android field staff. Dispatched emergency tasks immediately trigger hardware vibration and siren alarms on mobile devices.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedSilver),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: state.isHqWsConnected ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: state.isHqWsConnected ? const Color(0xFF10B981).withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulsingRadarDot(),
                const SizedBox(width: 8),
                Text(
                  state.isHqWsConnected ? 'HQ WEBSOCKET ONLINE :8765' : 'HQ WEBSOCKET OFFLINE',
                  style: GoogleFonts.inter(
                    color: state.isHqWsConnected ? const Color(0xFF10B981) : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(String qrPayload) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.uiAmber.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.uiAmber.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STAFF PAIRING QR CODE',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.uiAmber, letterSpacing: 0.6),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppTheme.mutedSilver, size: 18),
                tooltip: 'Copy Connection JSON to Clipboard',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrPayload));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied pairing configuration to clipboard!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // High-Contrast QR Code View
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 190.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Scan using EventGuard Staff Android App',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
          ),
          const SizedBox(height: 6),
          Text(
            'Target Host: ws://${_ipController.text}:${_portController.text}/field',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
          ),
          const SizedBox(height: 12),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetButton('Staff 01 (Gate A)', 'STAFF-001', 'SECURITY-A', 'Zone A (Main Concourse)'),
              _buildPresetButton('Staff 02 (Plaza)', 'STAFF-002', 'CROWD-CONTROL', 'Zone B (North Plaza)'),
              _buildPresetButton('Medic 01 (Aid Post)', 'MEDIC-01', 'FIRST-RESPONDERS', 'Zone A (Main Concourse)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, String staffId, String team, String zone) {
    return ActionChip(
      backgroundColor: const Color(0xFF1F2432),
      side: const BorderSide(color: AppTheme.hairlineBorder),
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.titaniumWhite)),
      onPressed: () {
        setState(() {
          _staffIdController.text = staffId;
          _selectedTeam = team;
          _selectedZone = zone;
        });
      },
    );
  }

  Widget _buildAllocationConfigCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALLOCATION & NETWORK SETTINGS',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite, letterSpacing: 0.6),
              ),
              TextButton.icon(
                icon: const Icon(Icons.wifi_find_rounded, size: 16, color: AppTheme.uiAmber),
                label: Text('Auto-Detect LAN IP', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.uiAmber)),
                onPressed: _autoDetectLocalIp,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Host IP & Port Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  label: 'HQ Wi-Fi / LAN IP',
                  controller: _ipController,
                  icon: Icons.computer_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  label: 'WS Port',
                  controller: _portController,
                  icon: Icons.tag_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Staff ID & Security Token Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Staff Call Sign / ID',
                  controller: _staffIdController,
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTextField(
                  label: 'Enrollment Token',
                  controller: _tokenController,
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Team & Zone Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Assigned Team / Unit',
                  value: _selectedTeam,
                  items: _teamOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTeam = val);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdown(
                  label: 'Venue Zone Location',
                  value: _selectedZone,
                  items: _zoneOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedZone = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF181C28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.hairlineBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.uiAmber, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ensure Android phone is connected to the same Wi-Fi router / local network as this HQ machine. Port 8765 must be accessible on Windows Firewall.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedStaffRoster(List<Map<String, dynamic>> connectedStaff) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE CONNECTED FIELD STAFF (${connectedStaff.length})',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite, letterSpacing: 0.6),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.mutedSilver),
                tooltip: 'Refresh Roster from Server',
                onPressed: () => context.read<MockState>().refreshStaffRoster(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (connectedStaff.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.hairlineBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppTheme.mutedSilver, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No Field Staff Currently Online',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan the QR code with the Staff App or launch the staff mobile client to pair.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: connectedStaff.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final staff = connectedStaff[idx];
                final staffId = staff['staffId'] ?? 'STAFF';
                final teamId = staff['teamId'] ?? 'SECURITY';
                final zone = staff['zone'] ?? 'Zone A';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B27),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const PulsingRadarDot(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$staffId • $teamId',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
                            ),
                            Text(
                              'Assigned: $zone • Status: Ready',
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          setState(() {
                            _deployTarget = staffId;
                            _deployTitleController.text = 'Priority Response: $zone';
                            _deployLocationController.text = zone;
                          });
                        },
                        child: Text('TARGET', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyDispatchConsole(List<Map<String, dynamic>> connectedStaff) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'EMERGENCY DEPLOYMENT & ALARM DISPATCH',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Target Selector
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  label: 'Dispatch Target',
                  value: _deployTarget,
                  items: [
                    'ALL',
                    'SECURITY-A',
                    'CROWD-CONTROL',
                    'FIRST-RESPONDERS',
                    ...connectedStaff.map((s) => s['staffId'].toString()).toSet(),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _deployTarget = val);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  label: 'Priority',
                  value: _deployPriority,
                  items: const ['CRITICAL', 'HIGH_WARNING', 'NORMAL'],
                  onChanged: (val) {
                    if (val != null) setState(() => _deployPriority = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildTextField(
            label: 'Incident Title',
            controller: _deployTitleController,
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 12),

          _buildTextField(
            label: 'Deployment Location / Zone',
            controller: _deployLocationController,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),

          _buildTextField(
            label: 'Instructions & Safety Orders',
            controller: _deployMessageController,
            icon: Icons.message_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Big Red Alarm Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isDispatching
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.notifications_active_rounded, color: Colors.white),
              label: Text(
                _isDispatching
                    ? 'DISPATCHING EMERGENCY ALARM...'
                    : 'DEPLOY STEWARDS & TRIGGER MOBILE ALARMS',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5, color: Colors.white),
              ),
              onPressed: _isDispatching ? null : _handleEmergencyDispatch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedSilver)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.mutedSilver, size: 18),
            filled: true,
            fillColor: const Color(0xFF141824),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.hairlineBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.hairlineBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.uiAmber)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedSilver)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141824),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.hairlineBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              dropdownColor: AppTheme.charcoalSurface,
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.mutedSilver),
              style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
