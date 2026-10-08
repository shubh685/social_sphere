import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Apis/api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  int forgotStep = 0;

  final _forgotEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  final List<TextEditingController> _otpControllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(5, (_) => FocusNode());

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  late AnimationController _bgAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _bgAnimation;
  late Animation<double> _glowAnimation;

  static const Color _accent = Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowAnimationController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 5; i++) {
      _otpFocus[i].addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _glowAnimationController.dispose();
    _forgotEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocus) {
      f.dispose();
    }
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

  Future<void> _handleStepNext() async {
    final email = _forgotEmailController.text.trim();

    if (forgotStep == 0) {
      if (email.isEmpty || !email.contains('@')) {
        _showSnackBar('Please enter a valid email address.');
        return;
      }

      setState(() => _isLoading = true);
      final res = await ApiService.forgotSendOtp(email: email);
      setState(() => _isLoading = false);

      if (res['status'] == true) {
        _showSnackBar('5-digit OTP sent to $email', isError: false);
        setState(() => forgotStep = 1);
      } else {
        _showSnackBar(res['message'] ?? 'Unable to send OTP.');
      }
    } else if (forgotStep == 1) {
      final code = _otpControllers.map((c) => c.text.trim()).join();
      if (code.length < 5) {
        _showSnackBar('Please enter the 5-digit verification code.');
        return;
      }

      setState(() => _isLoading = true);
      final res = await ApiService.forgotVerifyOtp(email: email, otp: code);
      setState(() => _isLoading = false);

      if (res['status'] == true) {
        _showSnackBar('OTP verified successfully!', isError: false);
        setState(() => forgotStep = 2);
      } else {
        _showSnackBar(res['message'] ?? 'Invalid verification code.');
      }
    } else if (forgotStep == 2) {
      final pwd = _newPasswordController.text;
      if (pwd.length < 6) {
        _showSnackBar('Password must be at least 6 characters.');
        return;
      }
      if (pwd != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match.');
        return;
      }

      setState(() => _isLoading = true);
      final res = await ApiService.resetPassword(email: email, password: pwd);
      setState(() => _isLoading = false);

      if (res['status'] == true) {
        _showSnackBar('Password updated successfully!', isError: false);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar(res['message'] ?? 'Failed to reset password.');
      }
    }
  }

  Future<void> _resendOtp() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    final res = await ApiService.forgotSendOtp(email: email);
    setState(() => _isLoading = false);

    if (res['status'] == true) {
      _showSnackBar('New code sent to your email!', isError: false);
    } else {
      _showSnackBar(res['message'] ?? 'Failed to resend code.');
    }
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
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () {
                  if (forgotStep > 0) {
                    setState(() => forgotStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                _buildDecorativeOrbs(size),
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 80 : 100,
                      horizontal: 16,
                    ),
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
                          _buildHeader(isMobile),
                          SizedBox(height: isMobile ? 20 : 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepBubble(1, "Email", forgotStep >= 0),
                              _buildStepLine(forgotStep >= 1),
                              _buildStepBubble(2, "Verify", forgotStep >= 1),
                              _buildStepLine(forgotStep >= 2),
                              _buildStepBubble(3, "Reset", forgotStep >= 2),
                            ],
                          ),
                          const SizedBox(height: 26),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildStepContent(),
                          ),
                          const SizedBox(height: 22),
                          _buildNavButtons(),
                        ],
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

  Widget _buildHeader(bool isMobile) {
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
                Icons.lock_reset_rounded,
                color: Color(0xFF00F0FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Reset Password",
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
          "We'll help you get back into your account",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 13 : 14,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    if (forgotStep == 0) {
      return Column(
        key: const ValueKey('forgotStep0'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel("Recover Your Account"),
          const SizedBox(height: 8),
          Text(
            "Enter the email associated with your account and we'll send you a 5-digit verification code.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: "Email Address",
            controller: _forgotEmailController,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      );
    } else if (forgotStep == 1) {
      return Column(
        key: const ValueKey('forgotStep1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel("Enter Verification Code"),
          const SizedBox(height: 8),
          Text(
            "We sent a 5-digit code to\n${_forgotEmailController.text.isEmpty ? 'your email' : _forgotEmailController.text}",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildOtpFields(
            controllers: _otpControllers,
            focusNodes: _otpFocus,
            length: 5,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _resendOtp,
              child: Text(
                "Resend Code",
                style: GoogleFonts.outfit(
                  color: _accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey('forgotStep2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel("Create New Password"),
          const SizedBox(height: 20),
          _buildTextField(
            label: "New Password",
            controller: _newPasswordController,
            obscure: true,
            isObscured: _obscureNewPass,
            icon: Icons.lock_outline_rounded,
            onToggleObscure: () => setState(() => _obscureNewPass = !_obscureNewPass),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Confirm Password",
            controller: _confirmPasswordController,
            obscure: true,
            isObscured: _obscureConfirmPass,
            icon: Icons.lock_reset_rounded,
            onToggleObscure: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
          ),
        ],
      );
    }
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (forgotStep > 0)
          Expanded(
            child: _buildOutlineButton(
              label: "Back",
              onPressed: () => setState(() => forgotStep--),
            ),
          ),
        if (forgotStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: forgotStep > 0 ? 2 : 1,
          child: _buildPrimaryButton(
            label: _isLoading
                ? "Processing..."
                : forgotStep == 2
                ? "Reset Password"
                : forgotStep == 1
                ? "Verify Code"
                : "Send Code",
            onPressed: _isLoading ? () {} : _handleStepNext,
            icon: forgotStep == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required int length,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = (constraints.maxWidth - 4 * 12) / 5;
        final size = boxSize.clamp(44.0, 60.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i == length - 1 ? 0 : 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: size,
                height: size * 1.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: focusNodes[i].hasFocus ? _accent : Colors.white.withOpacity(0.15),
                    width: focusNodes[i].hasFocus ? 2.0 : 1.2,
                  ),
                  boxShadow: focusNodes[i].hasFocus
                      ? [
                    BoxShadow(
                      color: _accent.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: TextField(
                    controller: controllers[i],
                    focusNode: focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.outfit(
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && i < length - 1) {
                        focusNodes[i + 1].requestFocus();
                      }
                      if (value.isEmpty && i > 0) {
                        focusNodes[i - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
            );
          }),
        );
      },
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
              colors: [Color(0xFFFF6B9D), Color(0xFFA855F7)],
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

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white.withOpacity(0.75),
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStepBubble(int stepNum, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive ? const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFA855F7)]) : null,
            color: isActive ? null : Colors.transparent,
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: isActive ? [BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 12)] : null,
          ),
          child: Center(
            child: Text(
              "$stepNum",
              style: GoogleFonts.outfit(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.35),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 32,
      height: 2.5,
      margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: isActive ? const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFA855F7)]) : null,
        color: isActive ? null : Colors.white.withOpacity(0.12),
      ),
    );
  }
}