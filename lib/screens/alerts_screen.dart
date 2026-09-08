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

    final filteredAlerts = state.alerts.where((a) {
      if (_selectedFilter == 'Critical' && a.severity != AlertSeverity.critical) return false;
      if (_selectedFilter == 'Active' && a.status != AlertStatus.active) return false;
      if (_selectedFilter == 'Resolved' && a.status != AlertStatus.resolved) return false;
      if (query.isNotEmpty) {
        return a.id.toLowerCase().contains(query) ||
            a.title.toLowerCase().contains(query) ||
            a.location.toLowerCase().contains(query) ||
            a.cameraId.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Container(
      color: AppTheme.obsidianBlack,
      child: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.charcoalSurface,
              border: Border(bottom: BorderSide(color: AppTheme.hairlineBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', count: state.alerts.length),
                        _buildFilterChip('Critical', count: state.alerts.where((a) => a.severity == AlertSeverity.critical).length, isCritical: true),
                        _buildFilterChip('Active', count: state.alerts.where((a) => a.status == AlertStatus.active).length),
                        _buildFilterChip('Resolved', count: state.alerts.where((a) => a.status == AlertStatus.resolved).length),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 280,
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search alert ID, sector, camera...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.tacticalAmber),
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
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.tacticalAmber, width: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alert List
          Expanded(
            child: filteredAlerts.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoalSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.hairlineBorder),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.obsidianBlack,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: const Icon(Icons.verified_user_outlined, color: AppTheme.radarGreen, size: 40),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            state.alerts.isEmpty
                                ? 'PERIMETER DEFENSE CLEAR • ZERO ACTIVE BREACHES'
                                : 'NO ALERTS MATCH FILTER "$_selectedFilter"',
                            style: GoogleFonts.inter(
                              color: AppTheme.titaniumWhite,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.alerts.isEmpty
                                ? 'All sector nodes operating nominally. Camera feed actively scanned by YOLO model.'
                                : 'Try selecting the "All" filter chip or clearing your search term.',
                            style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          if (state.alerts.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.tacticalAmber,
                                foregroundColor: AppTheme.obsidianBlack,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = 'All';
                                  _searchController.clear();
                                });
                              },
                              child: Text('RESET FILTERS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      return _InteractiveAlertListItem(
                        alert: filteredAlerts[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {int count = 0, bool isCritical = false}) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isCritical ? AppTheme.alertRed : AppTheme.tacticalAmber)
                : AppTheme.obsidianBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isCritical ? AppTheme.alertRed : AppTheme.tacticalAmber)
                  : AppTheme.hairlineBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? AppTheme.obsidianBlack : AppTheme.titaniumWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.obsidianBlack.withValues(alpha: 0.2)
                      : AppTheme.charcoalElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    color: isSelected ? AppTheme.obsidianBlack : AppTheme.mutedSilver,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveAlertListItem extends StatefulWidget {
  final Alert alert;

  const _InteractiveAlertListItem({Key? key, required this.alert}) : super(key: key);

  @override
  State<_InteractiveAlertListItem> createState() => _InteractiveAlertListItemState();
}

class _InteractiveAlertListItemState extends State<_InteractiveAlertListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final bool isCritical = alert.severity == AlertSeverity.critical;
    final bool isActive = alert.status == AlertStatus.active;
    final Color badgeColor = isCritical ? AppTheme.alertRed : AppTheme.tacticalAmber;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.008 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCritical && isActive
                  ? AppTheme.alertRed
                  : (_isHovered ? AppTheme.tacticalAmber : AppTheme.hairlineBorder),
              width: isCritical && isActive || _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isCritical && isActive
                    ? AppTheme.alertRed.withValues(alpha: 0.2)
                    : (_isHovered ? AppTheme.tacticalAmber.withValues(alpha: 0.12) : Colors.black26),
                blurRadius: _isHovered ? 14 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge with Glowing Aura
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  isCritical ? Icons.warning_amber_rounded : Icons.shield_outlined,
                  color: badgeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 18),

              // Title and Intel Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? badgeColor.withValues(alpha: 0.18) : AppTheme.radarGreen.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isActive ? badgeColor : AppTheme.radarGreen),
                          ),
                          child: Text(
                            alert.status.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: isActive ? badgeColor : AppTheme.radarGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          alert.id,
                          style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '• ${alert.detectedAt.toString().substring(0, 16)}',
                          style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.titaniumWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sensor: ${alert.cameraId}   |   Sector: ${alert.location}',
                      style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // Actions
              if (isActive) ...[
                OutlinedButton(
                  onPressed: () => context.read<MockState>().acknowledgeAlert(alert.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.titaniumWhite,
                    side: const BorderSide(color: AppTheme.hairlineBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('ACKNOWLEDGE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => context.read<MockState>().resolveAlert(alert.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tacticalAmber,
                    foregroundColor: AppTheme.obsidianBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('RESOLVE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.radarGreen.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppTheme.radarGreen),
                      const SizedBox(width: 6),
                      Text(
                        'RESOLVED',
                        style: GoogleFonts.inter(color: AppTheme.radarGreen, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
