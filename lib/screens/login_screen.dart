import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController(text: 'commander_alpha');
  final TextEditingController _passController = TextEditingController(text: '••••••••••••');
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isButtonHovered = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.charcoalSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.hairlineBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 36,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Security Shield Emblem with glowing aura
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.tacticalAmber.withOpacity(0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tacticalAmber.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.security, size: 44, color: AppTheme.tacticalAmber),
                    ),
                    const SizedBox(height: 22),
                    
                    // Title
                    Text(
                      'BORDERGUARD AI',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.titaniumWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.hairlineBorder),
                      ),
                      child: Text(
                        'SECURED AUTONOMOUS DEFENSE TERMINAL',
                        style: GoogleFonts.inter(
                          color: AppTheme.tacticalAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Username input
                    TextField(
                      controller: _userController,
                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Operator / Tactical Call-sign',
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.mutedSilver, size: 19),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password input
                    TextField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Cryptographic Security Key',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.mutedSilver, size: 19),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppTheme.mutedSilver,
                            size: 19,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Remember me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Retain station session',
                              style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Emergency Bypass',
                            style: GoogleFonts.inter(
                              color: AppTheme.mutedSilver,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // SUBMIT BUTTON with smooth hover scale and glowing amber shadow
                    MouseRegion(
                      onEnter: (_) => setState(() => _isButtonHovered = true),
                      onExit: (_) => setState(() => _isButtonHovered = false),
                      child: AnimatedScale(
                        scale: _isButtonHovered ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.tacticalAmber.withOpacity(_isButtonHovered ? 0.45 : 0.25),
                                blurRadius: _isButtonHovered ? 18 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.tacticalAmber,
                              foregroundColor: AppTheme.obsidianBlack,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/main');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login_rounded, size: 20, color: AppTheme.obsidianBlack),
                                const SizedBox(width: 10),
                                Text(
                                  'AUTHENTICATE & ENTER',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: AppTheme.obsidianBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Authorized Personnel Notice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 14, color: AppTheme.tacticalAmber),
                        const SizedBox(width: 8),
                        Text(
                          'RESTRICTED FACILITY • ENCRYPTED SESSION',
                          style: GoogleFonts.inter(
                            color: AppTheme.mutedSilver,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
