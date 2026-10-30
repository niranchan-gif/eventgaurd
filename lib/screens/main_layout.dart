import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mock/mock_state.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'live_surveillance_screen.dart';
import 'map_screen.dart';
import 'alerts_screen.dart';
import 'staff_management_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LiveSurveillanceScreen(),
    MapScreen(),
    AlertsScreen(),
    StaffManagementScreen(),
  ];

  final List<String> _titles = const [
    'Event Command & Operations (HQ)',
    'Live AI Monitoring & Neural Grid',
    'Venue Map & Steward Deployment',
    'Crowd Safety & Incident Response',
    'Staff Allocation & Mobile QR Pairing',
  ];


  void _showDeployDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151722),
          title: const Text('DISPATCH EVENT STEWARDS', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Staff/Team: SECURITY-A', style: TextStyle(color: Colors.grey)),
              Text('Task: Gate A Crowd Flow Control', style: TextStyle(color: Colors.white)),
              Text('Message: Proceed to Gate A entrance to manage attendee influx.', style: TextStyle(color: Colors.white)),
              Text('Priority: HIGH', style: TextStyle(color: Colors.redAccent)),
              Text('Location: Main Entrance Concourse', style: TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                _sendDeployCommand();
                Navigator.pop(context);
              },
              child: const Text('DISPATCH', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendDeployCommand() async {
    try {
      if (mounted) {
        final state = context.read<MockState>();
        await state.sendDeployCommand(
          teamId: "SECURITY-A",
          title: "Gate A Crowd Flow Control",
          description: "Proceed to Gate A entrance to manage attendee influx.",
          priority: "HIGH",
          locationName: "Main Entrance Concourse",
        );
      }
    } catch (e) {
      debugPrint('Deploy error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.groups_rounded, color: Colors.white),
        label: const Text('DISPATCH STEWARDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showDeployDialog(context),
      ),
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              if (_selectedIndex != index) {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(title: _titles[_selectedIndex]),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.01, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
