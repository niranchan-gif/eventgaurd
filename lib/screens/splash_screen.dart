import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkOlive, // 1st priority: #2E2910
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.deepGreen, // 2nd priority: #2C5745
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.orange, width: 2), // 4th priority: #EB7D00
              ),
              child: const Icon(Icons.security, size: 70, color: AppTheme.orange),
            ),
            const SizedBox(height: 28),
            Text(
              'BorderGuard AI',
              style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w800, color: AppTheme.cream, letterSpacing: 1.2), // 3rd: #EBE3A7
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.deepGreen,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'TACTICAL PERIMETER DEFENSE & INTELLIGENCE',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.orange, letterSpacing: 0.8),
              ),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppTheme.orange,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'INITIALIZING DEFENSE GRID & TELEMETRY...',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
