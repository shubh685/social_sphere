import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialee_sphere/dashboard.dart';
import 'Apis/api.dart';
import 'register.dart';
import 'forgot_pwd.dart';

class LogIN extends StatefulWidget {
  const LogIN({super.key});

  @override
  State<LogIN> createState() => _LogINState();
}

class _LogINState extends State<LogIN> with TickerProviderStateMixin {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPass = true;
  bool _isLoading = false;

  late AnimationController _bgAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _bgAnimation;
  late Animation<double> _cardScale;
  late Animation<double> _glowAnimation;

  static const Color _accent = Color(0xFF00F0FF);

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );

    _cardScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardAnimationController, curve: Curves.easeOutBack),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
          parent: _glowAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _cardAnimationController.dispose();
    _glowAnimationController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFFF4757) : const Color(0xFF00E5A0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in both email and password.");
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.login(email: email, password: password);
    setState(() => _isLoading = false);

    if (res['status'] == true) {
      _showSnackBar("Login successful!", isError: false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }
    } else {
      _showSnackBar(res['message'] ?? 'Login failed. Please try again.');
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToForgot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;
    final isMobile = size.width <= 600;

    final cardWidth = isDesktop ? 480.0 : isTablet ? size.width * 0.65 : size.width * 0.92;
    final horizontalPadding = isDesktop ? 40.0 : isTablet ? 32.0 : 22.0;

    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF0A0E27), const Color(0xFF1A0B2E), _bgAnimation.value)!,
                Color.lerp(const Color(0xFF1E1B4B), const Color(0xFF2D1B69), _bgAnimation.value)!,
                Color.lerp(const Color(0xFF311042), const Color(0xFF0F172A), _bgAnimation.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                _buildDecorativeOrbs(size),
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 24 : 40,
                      horizontal: 16,
                    ),
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: Container(
                        width: cardWidth,
                        padding: EdgeInsets.all(horizontalPadding),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0F1E).withOpacity(0.88),
                          borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
                          border: Border.all(
                            color: _accent.withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.18),
                              blurRadius: 40,
                              spreadRadius: 2,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBrandHeader(isMobile),
                            SizedBox(height: isMobile ? 24 : 32),
                            _buildTextField(
                              label: "Email Address",
                              controller: _loginEmailController,
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: "Password",
                              controller: _loginPasswordController,
                              obscure: true,
                              isObscured: _obscureLoginPass,
                              icon: Icons.lock_outline_rounded,
                              onToggleObscure: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _goToForgot,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Forgot Password?",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFC084FC),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildPrimaryButton(
                              label: _isLoading ? "Logging in..." : "Log In",
                              onPressed: _isLoading ? () {} : _handleLogin,
                              icon: _isLoading ? null : Icons.arrow_forward_rounded,
                            ),
                            SizedBox(height: isMobile ? 16 : 22),
                            Center(
                              child: GestureDetector(
                                onTap: _goToRegister,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      fontSize: isMobile ? 13 : 14,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    children: [
                                      const TextSpan(text: "Don't have an agency account? "),
                                      TextSpan(
                                        text: "Register",
                                        style: GoogleFonts.outfit(
                                          color: _accent,
                                          fontWeight: FontWeight.w700,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorativeOrbs(Size size) {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: -size.height * 0.1 + (_bgAnimation.value * 40),
              left: -size.width * 0.1,
              child: _glowOrb(size: size.width * 0.45, color: _accent.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -size.height * 0.15 - (_bgAnimation.value * 30),
              right: -size.width * 0.1,
              child: _glowOrb(size: size.width * 0.5, color: const Color(0xFFA855F7).withOpacity(0.1)),
            ),
          ],
        );
      },
    );
  }

  Widget _glowOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  Widget _buildBrandHeader(bool isMobile) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.login_rounded,
                color: Color(0xFF00F0FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Agency Sign IN",
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Sign in to continue managing your social presence",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 13 : 14,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool obscure = false,
    bool isObscured = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure && isObscured,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      cursorColor: _accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5), fontSize: 14),
        floatingLabelStyle: GoogleFonts.outfit(color: _accent, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white.withOpacity(0.4), size: 20) : null,
        suffixIcon: obscure
            ? IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white.withOpacity(0.4),
            size: 20,
          ),
          onPressed: onToggleObscure,
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF00F0FF), Color(0xFFA855F7)],
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                else ...[
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 19),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}