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
      backgroundColor: AppTheme.obsidianBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.charcoalSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.tacticalAmber, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tacticalAmber.withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.security, size: 64, color: AppTheme.tacticalAmber),
            ),
            const SizedBox(height: 28),
            Text(
              'BORDERGUARD AI',
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
              'INITIALIZING DEFENSE SENSOR GRID & AI PIPELINES...',
              style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
