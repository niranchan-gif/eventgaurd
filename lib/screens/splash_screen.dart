import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _bootStatus = 'INITIALIZING DEFENSE SENSOR GRID & AI PIPELINES...';

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  void _startBootSequence() async {
    // Step 1: Camera Grid Link
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _bootStatus = 'COMMENCING HARDWARE LINK: CAM-01 [LAPTOP] & CAM-02 [PHONE RECON]...';
      });
    }

    // Step 2: Auto-Authentication of Defense Commander
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      context.read<MockState>().instantCommanderLogin();
      setState(() {
        _bootStatus = 'AUTOMATIC BIOMETRIC CLEARANCE: COMMANDER SARAH VANCE...';
      });
    }

    // Step 3: Launch Tactical Operations Center
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _bootStatus = 'SYSTEM INITIALIZED • DEPLOYING TACTICAL OPERATIONS CENTER';
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tacticalAmber.withValues(alpha: 0.3),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'EVENTGUARD AI',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.titaniumWhite,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.charcoalSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.hairlineBorder),
              ),
              child: Text(
                'TACTICAL PERIMETER DEFENSE & INTELLIGENCE SUITE',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.tacticalAmber, letterSpacing: 1.0),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: AppTheme.tacticalAmber,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _bootStatus,
              style: GoogleFonts.inter(color: AppTheme.tacticalAmber, fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
