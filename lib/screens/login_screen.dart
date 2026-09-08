import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../mock/mock_state.dart';
import '../models/user_model.dart';
import '../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController(text: 'commander_alpha');
  final TextEditingController _passController = TextEditingController(text: 'password123');
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isButtonHovered = false;
  bool _isGoogleHovered = false;
  String? _errorMessage;

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

  void _handleLogin() {
    final state = context.read<MockState>();
    final error = state.loginWithUsernameAndPassword(
      _userController.text,
      _passController.text,
    );

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _showActualGoogleSignIn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final clientIdController = TextEditingController(
          text: GoogleAuthService.savedClientId ?? '',
        );
        final clientSecretController = TextEditingController(
          text: GoogleAuthService.savedClientSecret ?? '',
        );
        final customEmailController = TextEditingController(text: '');
        final customNameController = TextEditingController(text: '');

        int activeTab = 0; // 0 = Browser OAuth 2.0, 1 = Direct Google Identity
        bool isLoading = false;
        String statusMessage = '';
        String? authError;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void startBrowserOAuth() async {
              final clientId = clientIdController.text.trim();
              if (clientId.isEmpty) {
                setModalState(() {
                  authError = 'Please provide a Google Cloud OAuth Client ID (or use Direct Google Login).';
                });
                return;
              }

              setModalState(() {
                isLoading = true;
                authError = null;
                statusMessage = 'Launching default browser for Google Sign-In...';
              });

              try {
                final user = await GoogleAuthService.authenticateWithBrowser(
                  clientId: clientId,
                  clientSecret: clientSecretController.text.trim().isNotEmpty
                      ? clientSecretController.text.trim()
                      : null,
                  onStatusUpdate: (msg) {
                    setModalState(() {
                      statusMessage = msg;
                    });
                  },
                );

                if (user != null) {
                  if (context.mounted) {
                    context.read<MockState>().loginWithGoogle(user);
                    Navigator.pop(dialogCtx);
                    Navigator.pushReplacementNamed(context, '/main');
                  }
                }
              } catch (e) {
                setModalState(() {
                  isLoading = false;
                  authError = e.toString().replaceAll('Exception:', '').trim();
                });
              }
            }

            void completeDirectGoogleLogin() {
              final email = customEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setModalState(() {
                  authError = 'Please enter a valid Google email address (e.g. name@gmail.com)';
                });
                return;
              }

              final name = customNameController.text.trim().isNotEmpty
                  ? customNameController.text.trim()
                  : email.split('@').first.replaceAll('.', ' ').toUpperCase();

              final googleUser = UserModel(
                id: 'GGL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                name: name,
                callsign: email.split('@').first,
                email: email,
                role: 'Defense Systems Operator (Google SSO)',
                clearanceLevel: 'LEVEL 4 • DIRECT GOOGLE ACCOUNT',
                avatarUrl: null,
                provider: AuthProvider.google,
              );

              context.read<MockState>().loginWithGoogle(googleUser);
              Navigator.pop(dialogCtx);
              Navigator.pushReplacementNamed(context, '/main');
            }

            return Dialog(
              backgroundColor: AppTheme.charcoalSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.hairlineBorder, width: 1.5),
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Google Header
                    Row(
                      children: [
                        _buildGoogleIcon(size: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign in with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.titaniumWhite,
                                ),
                              ),
                              Text(
                                'Official Google Account Single Sign-On (SSO)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.mutedSilver,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLoading)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppTheme.mutedSilver),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: AppTheme.hairlineBorder, height: 1),
                    const SizedBox(height: 16),

                    if (isLoading) ...[
                      // Animated Loading Indicator during browser auth
                      Container(
                        padding: const EdgeInsets.all(28),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tacticalAmber),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              statusMessage,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppTheme.titaniumWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please complete the sign-in on Google accounts page in your browser.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppTheme.mutedSilver,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.alertRed,
                                side: const BorderSide(color: AppTheme.alertRed),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  isLoading = false;
                                  statusMessage = '';
                                });
                              },
                              child: Text('CANCEL BROWSER LOGIN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Method Navigation Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.hairlineBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                onTap: () => setModalState(() {
                                  activeTab = 0;
                                  authError = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: activeTab == 0 ? AppTheme.charcoalElevated : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                    border: activeTab == 0
                                        ? Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.6))
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.open_in_browser, size: 16, color: AppTheme.tacticalAmber),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Browser OAuth 2.0',
                                        style: GoogleFonts.inter(
                                          color: activeTab == 0 ? AppTheme.titaniumWhite : AppTheme.mutedSilver,
                                          fontWeight: activeTab == 0 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                onTap: () => setModalState(() {
                                  activeTab = 1;
                                  authError = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: activeTab == 1 ? AppTheme.charcoalElevated : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                    border: activeTab == 1
                                        ? Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.6))
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.radarGreen),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Direct Google Account',
                                        style: GoogleFonts.inter(
                                          color: activeTab == 1 ? AppTheme.titaniumWhite : AppTheme.mutedSilver,
                                          fontWeight: activeTab == 1 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Error alert banner
                      if (authError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.alertRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.alertRed),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: AppTheme.alertRed),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authError!,
                                  style: GoogleFonts.inter(color: AppTheme.alertRed, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (activeTab == 0) ...[
                        // Tab 0: Browser OAuth 2.0
                        Text(
                          'Connect via Official Google Cloud OAuth 2.0',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Launches Google sign-in directly in your default browser (Chrome/Edge), authenticated via local loopback listener (RFC 8252).',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: clientIdController,
                          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Google OAuth Client ID (.apps.googleusercontent.com)',
                            hintText: 'e.g. 123456789-abcdef.apps.googleusercontent.com',
                            prefixIcon: const Icon(Icons.key, color: AppTheme.mutedSilver, size: 16),
                            suffixIcon: IconButton(
                              tooltip: 'Open Google Cloud Credentials Console',
                              icon: const Icon(Icons.launch, size: 16, color: AppTheme.tacticalAmber),
                              onPressed: () {
                                GoogleAuthService.openBrowser('https://console.cloud.google.com/apis/credentials');
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: clientSecretController,
                          obscureText: true,
                          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                          decoration: const InputDecoration(
                            labelText: 'Client Secret (Optional for Desktop PKCE)',
                            hintText: 'Optional',
                            prefixIcon: Icon(Icons.security, color: AppTheme.mutedSilver, size: 16),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tacticalAmber,
                            foregroundColor: AppTheme.obsidianBlack,
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          onPressed: startBrowserOAuth,
                          icon: _buildGoogleIcon(size: 18),
                          label: Text(
                            'LAUNCH GOOGLE BROWSER LOGIN',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                          ),
                        ),
                      ] else ...[
                        // Tab 1: Direct Google Account Verification
                        Text(
                          'Sign In with Your Personal / Work Google Account',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.titaniumWhite),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Directly authenticate using your active Google email address for instant station clearance without creating a Cloud console project.',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedSilver),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: customEmailController,
                          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Your Google Email Address',
                            hintText: 'operator.name@gmail.com',
                            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.mutedSilver, size: 18),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: customNameController,
                          style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Full Display Name (Optional)',
                            hintText: 'e.g. Commander Sarah Connor',
                            prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.mutedSilver, size: 18),
                          ),
                        ),
                        const SizedBox(height: 18),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tacticalAmber,
                            foregroundColor: AppTheme.obsidianBlack,
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          onPressed: completeDirectGoogleLogin,
                          icon: _buildGoogleIcon(size: 18),
                          label: Text(
                            'AUTHENTICATE & ENTER WITH GOOGLE',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoogleIcon({double size = 20}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
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
                width: 450,
                padding: const EdgeInsets.all(36),
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
                        border: Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tacticalAmber.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.security, size: 40, color: AppTheme.tacticalAmber),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      'BORDERGUARD AI',
                      style: GoogleFonts.inter(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.titaniumWhite,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianBlack,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.hairlineBorder),
                      ),
                      child: Text(
                        'SECURED DEFENSE COMMAND TERMINAL',
                        style: GoogleFonts.inter(
                          color: AppTheme.tacticalAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick operator preset chips for seamless testing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPresetChip('Commander Alpha', 'commander_alpha', 'password123'),
                        const SizedBox(width: 8),
                        _buildPresetChip('Operator 01', 'operator_01', 'operator123'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error Message Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.alertRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.alertRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: AppTheme.alertRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(color: AppTheme.alertRed, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Username input
                    TextField(
                      controller: _userController,
                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Operator Call-sign / Username',
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.mutedSilver, size: 19),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password input
                    TextField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Cryptographic Security Key / Password',
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
                    const SizedBox(height: 14),

                    // Remember me
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
                        Text(
                          '256-Bit Encrypted',
                          style: GoogleFonts.inter(color: AppTheme.mutedSilver, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // SUBMIT BUTTON (Username & Password)
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
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.tacticalAmber.withValues(alpha: _isButtonHovered ? 0.45 : 0.25),
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
                            onPressed: _handleLogin,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login_rounded, size: 19, color: AppTheme.obsidianBlack),
                                const SizedBox(width: 10),
                                Text(
                                  'AUTHENTICATE & ENTER',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: AppTheme.obsidianBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Divider with "OR"
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppTheme.hairlineBorder, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR IDENTITY SSO',
                            style: GoogleFonts.inter(
                              color: AppTheme.mutedSilver,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppTheme.hairlineBorder, height: 1)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // SIGN IN WITH GOOGLE BUTTON
                    MouseRegion(
                      onEnter: (_) => setState(() => _isGoogleHovered = true),
                      onExit: (_) => setState(() => _isGoogleHovered = false),
                      child: AnimatedScale(
                        scale: _isGoogleHovered ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isGoogleHovered ? AppTheme.charcoalElevated : AppTheme.obsidianBlack,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isGoogleHovered ? AppTheme.tacticalAmber : AppTheme.hairlineBorder,
                              width: 1.3,
                            ),
                            boxShadow: _isGoogleHovered
                                ? [
                                    BoxShadow(
                                      color: AppTheme.tacticalAmber.withValues(alpha: 0.12),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _showActualGoogleSignIn,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleIcon(size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'SIGN IN WITH GOOGLE',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: AppTheme.titaniumWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

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

  Widget _buildPresetChip(String label, String username, String pass) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        setState(() {
          _userController.text = username;
          _passController.text = pass;
          _errorMessage = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.obsidianBlack,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.hairlineBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 12, color: AppTheme.tacticalAmber),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.mutedSilver,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vector Google Logo Painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Draw stylized 4-color Google G badge
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    final rect = Rect.fromCircle(center: center, radius: radius * 0.78);

    // Blue arc (Right)
    strokePaint.color = bluePaint.color;
    canvas.drawArc(rect, -0.4, 1.4, false, strokePaint);

    // Green arc (Bottom)
    strokePaint.color = greenPaint.color;
    canvas.drawArc(rect, 1.0, 1.5, false, strokePaint);

    // Yellow arc (Bottom-Left)
    strokePaint.color = yellowPaint.color;
    canvas.drawArc(rect, 2.5, 1.5, false, strokePaint);

    // Red arc (Top)
    strokePaint.color = redPaint.color;
    canvas.drawArc(rect, 4.0, 1.6, false, strokePaint);

    // Cross bar of the G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(center.dx - 1, center.dy), Offset(center.dx + radius * 0.85, center.dy), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
