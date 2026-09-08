import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../mock/mock_state.dart';
import '../models/user_model.dart';
import '../models/alert.dart';

class TopBar extends StatelessWidget {
  final String title;
  const TopBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final user = state.currentUser ?? UserModel.commanderAlpha;
    final activeAlerts = state.alerts.where((a) => a.status == AlertStatus.active).length;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.obsidianBlack,
        border: Border(
          bottom: BorderSide(color: AppTheme.hairlineBorder, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Title area with tag
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.titaniumWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.charcoalSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.hairlineBorder),
                  ),
                  child: Text(
                    'TACTICAL C2',
                    style: GoogleFonts.inter(
                      color: AppTheme.tacticalAmber,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Live Armed Status with Pulsing Radar Halo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.charcoalSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.hairlineBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulsingRadarDot(),
                    const SizedBox(width: 8),
                    Text(
                      'DEFENSE GRID ACTIVE',
                      style: GoogleFonts.inter(
                        color: AppTheme.titaniumWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TopBarIconButton(
                icon: Icons.notifications_outlined,
                badgeCount: activeAlerts,
                tooltip: '$activeAlerts Active Breaches',
              ),
              const SizedBox(width: 12),
              // User profile button with dropdown
              PopupMenuButton<String>(
                color: AppTheme.charcoalSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.hairlineBorder),
                ),
                offset: const Offset(0, 48),
                onSelected: (value) {
                  if (value == 'logout') {
                    state.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.inter(
                                color: AppTheme.titaniumWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (user.provider == AuthProvider.google) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4285F4).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text('GOOGLE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF4285F4))),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(user.email, style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(user.clearanceLevel, style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: AppTheme.alertRed, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          'Sign Out Station',
                          style: GoogleFonts.inter(color: AppTheme.alertRed, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user.provider == AuthProvider.google ? const Color(0xFF4285F4) : AppTheme.tacticalAmber,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.charcoalElevated,
                      child: Text(
                        user.initials,
                        style: GoogleFonts.inter(
                          color: user.provider == AuthProvider.google ? const Color(0xFF4285F4) : AppTheme.tacticalAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PulsingRadarDot extends StatefulWidget {
  const PulsingRadarDot({Key? key}) : super(key: key);

  @override
  State<PulsingRadarDot> createState() => _PulsingRadarDotState();
}

class _PulsingRadarDotState extends State<PulsingRadarDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.radarGreen.withValues(alpha: _opacityAnimation.value),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.radarGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatefulWidget {
  final IconData icon;
  final int badgeCount;
  final String? tooltip;

  const _TopBarIconButton({required this.icon, this.badgeCount = 0, this.tooltip});

  @override
  State<_TopBarIconButton> createState() => _TopBarIconButtonState();
}

class _TopBarIconButtonState extends State<_TopBarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.charcoalElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: _isHovered ? AppTheme.tacticalAmber : AppTheme.titaniumWhite,
            ),
            if (widget.badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.tacticalAmber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.badgeCount}',
                    style: const TextStyle(
                      color: AppTheme.obsidianBlack,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    return button;
  }
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({Key? key, required this.selectedIndex, required this.onItemSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final user = state.currentUser ?? UserModel.commanderAlpha;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.obsidianBlack,
        border: Border(right: BorderSide(color: AppTheme.hairlineBorder, width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Tactical Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.charcoalSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.8), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.tacticalAmber.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield, size: 20, color: AppTheme.tacticalAmber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BorderGuard AI',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.titaniumWhite, letterSpacing: 0.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'C2 DEFENSE GRID',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.tacticalAmber, letterSpacing: 0.8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: AppTheme.hairlineBorder, height: 1),
          // Nav items list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _SidebarNavItem(index: 0, title: 'Dashboard Overview', icon: Icons.dashboard_outlined, isSelected: selectedIndex == 0, onTap: () => onItemSelected(0)),
                _SidebarNavItem(index: 1, title: 'Live Surveillance Grid', icon: Icons.videocam_outlined, isSelected: selectedIndex == 1, onTap: () => onItemSelected(1)),
                _SidebarNavItem(index: 2, title: 'Threats & Alert Feed', icon: Icons.warning_amber_rounded, isSelected: selectedIndex == 2, onTap: () => onItemSelected(2)),
                _SidebarNavItem(index: 3, title: 'Tactical Perimeter Map', icon: Icons.map_outlined, isSelected: selectedIndex == 3, onTap: () => onItemSelected(3)),
                _SidebarNavItem(index: 4, title: 'Incident Log & Dispatch', icon: Icons.assignment_outlined, isSelected: selectedIndex == 4, onTap: () => onItemSelected(4)),
                _SidebarNavItem(index: 5, title: 'Intelligence & Analytics', icon: Icons.analytics_outlined, isSelected: selectedIndex == 5, onTap: () => onItemSelected(5)),
                _SidebarNavItem(index: 6, title: 'Sensor Grid Nodes', icon: Icons.camera_alt_outlined, isSelected: selectedIndex == 6, onTap: () => onItemSelected(6)),
                _SidebarNavItem(index: 7, title: 'System Configuration', icon: Icons.settings_outlined, isSelected: selectedIndex == 7, onTap: () => onItemSelected(7)),
              ],
            ),
          ),
          const Divider(color: AppTheme.hairlineBorder, height: 1),
          // Operator Profile Card
          Container(
            padding: const EdgeInsets.all(14),
            color: AppTheme.charcoalSurface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: user.provider == AuthProvider.google ? const Color(0xFF4285F4) : AppTheme.tacticalAmber,
                  child: Text(
                    user.initials,
                    style: const TextStyle(color: AppTheme.obsidianBlack, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontWeight: FontWeight.w700, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.provider == AuthProvider.google) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 12, color: Color(0xFF4285F4)),
                          ],
                        ],
                      ),
                      Text(
                        user.role,
                        style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign Out Station',
                  icon: const Icon(Icons.logout, size: 16, color: AppTheme.mutedSilver),
                  splashRadius: 16,
                  onPressed: () {
                    state.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.index,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.charcoalElevated
                  : (_isHovered ? AppTheme.charcoalSurface : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppTheme.tacticalAmber.withValues(alpha: 0.45)
                    : (_isHovered ? AppTheme.hairlineBorder : Colors.transparent),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Accent indicator bar
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.tacticalAmber : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  widget.icon,
                  color: isSelected
                      ? AppTheme.tacticalAmber
                      : (_isHovered ? AppTheme.titaniumWhite : AppTheme.mutedSilver),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? AppTheme.titaniumWhite
                          : (_isHovered ? AppTheme.titaniumWhite : AppTheme.mutedSilver),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
