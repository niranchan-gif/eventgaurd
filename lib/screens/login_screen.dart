import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../mock/mock_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Authentication Form Controllers - prefilled with primary Commander for instant authorized access
  final TextEditingController _userController = TextEditingController(text: 'VANCE-01');
  final TextEditingController _passController = TextEditingController(text: 'Defense2026!');

  // Registration Form Controllers
  final TextEditingController _regUserController = TextEditingController();
  final TextEditingController _regPassController = TextEditingController();
  final TextEditingController _regConfirmPassController = TextEditingController();
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regRoleController = TextEditingController(text: 'Perimeter Defense Officer');
  String _regClearance = 'LEVEL 3 • FIELD OPERATOR';

  bool _isRegisterMode = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureRegPassword = true;
  bool _isButtonHovered = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _userController.dispose();
    _passController.dispose();
    _regUserController.dispose();
    _regPassController.dispose();
    _regConfirmPassController.dispose();
    _regNameController.dispose();
    _regRoleController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both your registered Callsign and Security Key.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final state = context.read<MockState>();
    final error = await state.loginWithUsernameAndPassword(username, password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _handleRegister() async {
    final username = _regUserController.text.trim();
    final password = _regPassController.text.trim();
    final confirm = _regConfirmPassController.text.trim();
    final name = _regNameController.text.trim();
    final role = _regRoleController.text.trim();

    if (username.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() {
        _errorMessage = 'Callsign, Password, and Full Name are strictly mandatory.';
        _successMessage = null;
      });
      return;
    }

    if (password.length < 4) {
      setState(() {
        _errorMessage = 'Security Key must contain at least 4 characters.';
        _successMessage = null;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _errorMessage = 'Security Keys do not match. Please re-type your key.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final state = context.read<MockState>();
    final error = await state.registerOperator(
      username: username,
      password: password,
      name: name,
      role: role.isNotEmpty ? role : 'Perimeter Defense Officer',
      clearanceLevel: _regClearance,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      body: Stack(
        children: [
          // Background tactical defense grid
          Positioned.fill(
            child: CustomPaint(
              painter: _TacticalGridPainter(),
            ),
          ),

          // Central authentication card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: 480,
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoalSurface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.hairlineBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Shield Emblem & Official App Logo
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.tacticalAmber.withValues(alpha: 0.25),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.charcoalElevated,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.tacticalAmber),
                                    ),
                                    child: const Icon(Icons.shield, color: AppTheme.tacticalAmber, size: 30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // System Title
                        Text(
                          'EVENTGUARD AI',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.orbitron(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                            color: AppTheme.titaniumWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CONFIDENTIAL TACTICAL C2 PERIMETER SURVEILLANCE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.mutedSilver,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Classified Security Vault Status Indicator (Pure Military Defense)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.obsidianBlack,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF2EA44F).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF2EA44F),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF2EA44F),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'MILITARY SECURITY VAULT: ACTIVE • CLASSIFIED LEVEL 5',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF2EA44F),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Mode Selector: SIGN IN vs ENROLL OPERATOR
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
                                  onTap: () {
                                    setState(() {
                                      _isRegisterMode = false;
                                      _errorMessage = null;
                                      _successMessage = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isRegisterMode ? AppTheme.charcoalElevated : Colors.transparent,
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                      border: !_isRegisterMode
                                          ? Border.all(color: AppTheme.tacticalAmber.withValues(alpha: 0.7))
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.login_rounded,
                                          size: 14,
                                          color: !_isRegisterMode ? AppTheme.tacticalAmber : AppTheme.mutedSilver,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'OPERATOR SIGN IN',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: !_isRegisterMode ? AppTheme.titaniumWhite : AppTheme.mutedSilver,
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
                                  onTap: () {
                                    setState(() {
                                      _isRegisterMode = true;
                                      _errorMessage = null;
                                      _successMessage = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isRegisterMode ? AppTheme.charcoalElevated : Colors.transparent,
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                      border: _isRegisterMode
                                          ? Border.all(color: const Color(0xFF2EA44F).withValues(alpha: 0.7))
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add_alt_1,
                                          size: 14,
                                          color: _isRegisterMode ? const Color(0xFF2EA44F) : AppTheme.mutedSilver,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ENROLL NEW OPERATOR',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: _isRegisterMode ? AppTheme.titaniumWhite : AppTheme.mutedSilver,
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

                        // Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.alertRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 16, color: AppTheme.alertRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.alertRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Success Banner
                        if (_successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2EA44F).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF2EA44F).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2EA44F)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF2EA44F),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // VIEW 1: SIGN IN (Strictly registered operators only)
                        if (!_isRegisterMode) ...[
                          Text(
                            'OPERATOR CALL-SIGN',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.mutedSilver,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _userController,
                            style: GoogleFonts.inter(
                              color: AppTheme.titaniumWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter registered callsign',
                              hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver.withValues(alpha: 0.4), fontSize: 12),
                              prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppTheme.tacticalAmber),
                              filled: true,
                              fillColor: AppTheme.obsidianBlack,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppTheme.hairlineBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppTheme.tacticalAmber, width: 1.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            'SECURITY KEY / PASSWORD',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppTheme.mutedSilver,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(
                              color: AppTheme.titaniumWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter defense security key',
                              hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver.withValues(alpha: 0.4), fontSize: 12),
                              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppTheme.tacticalAmber),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  size: 18,
                                  color: AppTheme.mutedSilver,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: AppTheme.obsidianBlack,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppTheme.hairlineBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppTheme.tacticalAmber, width: 1.4),
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 12),

                          // Remember Checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppTheme.tacticalAmber,
                                  checkColor: AppTheme.obsidianBlack,
                                  side: const BorderSide(color: AppTheme.hairlineBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Persist Station Security Session',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.mutedSilver,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Main Login Button
                          MouseRegion(
                            onEnter: (_) => setState(() => _isButtonHovered = true),
                            onExit: (_) => setState(() => _isButtonHovered = false),
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
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.obsidianBlack),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login_rounded, size: 19, color: AppTheme.obsidianBlack),
                                          const SizedBox(width: 10),
                                          Text(
                                            'AUTHENTICATE & ENTER COMMAND',
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
                        ] else ...[
                          // VIEW 2: REGISTRATION (Enrolls into encrypted operators.enc)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CALL-SIGN / USERNAME',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.mutedSilver,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _regUserController,
                                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. sentry_lead',
                                        hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver.withValues(alpha: 0.4), fontSize: 11),
                                        filled: true,
                                        fillColor: AppTheme.obsidianBlack,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FULL OPERATOR NAME',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.mutedSilver,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _regNameController,
                                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Major Vikram',
                                        hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver.withValues(alpha: 0.4), fontSize: 11),
                                        filled: true,
                                        fillColor: AppTheme.obsidianBlack,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SECURITY KEY / PASSWORD',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.mutedSilver,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _regPassController,
                                      obscureText: _obscureRegPassword,
                                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'Min 4 chars',
                                        hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver.withValues(alpha: 0.4), fontSize: 11),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureRegPassword ? Icons.visibility_off : Icons.visibility,
                                            size: 16,
                                            color: AppTheme.mutedSilver,
                                          ),
                                          onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                                        ),
                                        filled: true,
                                        fillColor: AppTheme.obsidianBlack,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CONFIRM SECURITY KEY',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.mutedSilver,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _regConfirmPassController,
                                      obscureText: _obscureRegPassword,
                                      style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'Re-enter key',
                                        hintStyle: GoogleFonts.inter(color: AppTheme.mutedSilver.withValues(alpha: 0.4), fontSize: 11),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureRegPassword ? Icons.visibility_off : Icons.visibility,
                                            size: 16,
                                            color: AppTheme.mutedSilver,
                                          ),
                                          onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                                        ),
                                        filled: true,
                                        fillColor: AppTheme.obsidianBlack,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'TACTICAL DEFENSE ROLE',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedSilver),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _regRoleController,
                            style: GoogleFonts.inter(color: AppTheme.titaniumWhite, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'e.g. Surveillance Commander or Sensor Specialist',
                              filled: true,
                              fillColor: AppTheme.obsidianBlack,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'DEFENSE CLEARANCE LEVEL',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedSilver),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _regClearance,
                            dropdownColor: AppTheme.charcoalSurface,
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.titaniumWhite),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: AppTheme.obsidianBlack,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'LEVEL 3 • FIELD OPERATOR', child: Text('LEVEL 3 • FIELD OPERATOR')),
                              DropdownMenuItem(value: 'LEVEL 4 • RAPID RESPONSE', child: Text('LEVEL 4 • RAPID RESPONSE')),
                              DropdownMenuItem(value: 'LEVEL 5 • DEFCON-1 COMMAND', child: Text('LEVEL 5 • DEFCON-1 COMMAND')),
                              DropdownMenuItem(value: 'LEVEL 5 • ROOT C2 ARCHITECT', child: Text('LEVEL 5 • ROOT C2 ARCHITECT')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _regClearance = v);
                            },
                          ),
                          const SizedBox(height: 18),

                          // Register Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2EA44F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.shield_outlined, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ENROLL & SECURE OPERATOR',
                                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Security Classification Notice
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 13, color: AppTheme.tacticalAmber),
                            const SizedBox(width: 6),
                            Text(
                              'CLASSIFIED DEFENSE SYSTEM • REGISTERED OPERATORS ONLY',
                              style: GoogleFonts.inter(
                                color: AppTheme.mutedSilver,
                                fontSize: 9.5,
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
        ],
      ),
    );
  }
}

class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.hairlineBorder.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const double step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final cornerPaint = Paint()
      ..color = AppTheme.tacticalAmber.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;

    canvas.drawLine(const Offset(20, 20), const Offset(45, 20), cornerPaint);
    canvas.drawLine(const Offset(20, 20), const Offset(20, 45), cornerPaint);

    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 45, 20), cornerPaint);
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20, 45), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
