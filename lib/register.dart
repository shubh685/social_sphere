import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialee_sphere/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  /// 0 = Details, 1 = Verify (OTP), 2 = Password
  int currentStep = 0;
  static const int _totalSteps = 3;

  final _agencyNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _agencyEmailController = TextEditingController();

  // Password (Step 3)
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(4, (_) => FocusNode());

  late AnimationController _bgAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _bgAnimation;
  late Animation<double> _glowAnimation;

  static const Color _accent = Color(0xFFA855F7);

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
      CurvedAnimation(
          parent: _glowAnimationController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 4; i++) {
      _otpFocus[i].addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _glowAnimationController.dispose();
    _agencyNameController.dispose();
    _ownerNameController.dispose();
    _agencyEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  /// Called when the final step is completed successfully. Routes the user
  /// to the login page.
  void _handleComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Agency registered successfully! Please sign in.',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00E5A0).withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.push(context, MaterialPageRoute(builder: (context) => LogIN()));
  }

  /// Validates the current step's inputs. Returns true when it is safe to
  /// advance.
  bool _validateCurrentStep() {
    if (currentStep == 0) {
      if (_agencyNameController.text.trim().isEmpty ||
          _ownerNameController.text.trim().isEmpty ||
          _agencyEmailController.text.trim().isEmpty) {
        _showError('Please fill in all agency details.');
        return false;
      }
      if (!_agencyEmailController.text.contains('@')) {
        _showError('Please enter a valid email address.');
        return false;
      }
    } else if (currentStep == 1) {
      final code = _otpControllers.map((c) => c.text.trim()).join();
      if (code.length < 4) {
        _showError('Please enter the 4-digit verification code.');
        return false;
      }
    } else if (currentStep == 2) {
      final pwd = _passwordController.text;
      if (pwd.length < 6) {
        _showError('Password must be at least 6 characters.');
        return false;
      }
      if (pwd != _confirmPasswordController.text) {
        _showError('Passwords do not match.');
        return false;
      }
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFF4757).withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;
    final isMobile = size.width <= 600;

    final cardWidth =
    isDesktop ? 480.0 : isTablet ? size.width * 0.65 : size.width * 0.92;
    final horizontalPadding =
    isDesktop ? 40.0 : isTablet ? 32.0 : 22.0;

    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF0A0E27), const Color(0xFF1A0B2E),
                    _bgAnimation.value)!,
                Color.lerp(const Color(0xFF1E1B4B), const Color(0xFF2D1B69),
                    _bgAnimation.value)!,
                Color.lerp(const Color(0xFF311042), const Color(0xFF0F172A),
                    _bgAnimation.value)!,
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () {
                  if (currentStep > 0) {
                    setState(() => currentStep--);
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
                        borderRadius:
                        BorderRadius.circular(isMobile ? 22 : 28),
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

                          // ── Stepper (3 steps)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepBubble(1, "Details", currentStep >= 0),
                              _buildStepLine(currentStep >= 1),
                              _buildStepBubble(2, "Verify", currentStep >= 1),
                              _buildStepLine(currentStep >= 2),
                              _buildStepBubble(3, "Password", currentStep >= 2),
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
              right: -size.width * 0.1,
              child: _glowOrb(
                  size: size.width * 0.45,
                  color: _accent.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -size.height * 0.15 - (_bgAnimation.value * 30),
              left: -size.width * 0.1,
              child: _glowOrb(
                  size: size.width * 0.5,
                  color: const Color(0xFF00F0FF).withOpacity(0.1)),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xFF00F0FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Agency Onboarding",
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
          "Set up your agency profile in a few quick steps",
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
    // ── Step 1: Agency info
    if (currentStep == 0) {
      return Column(
        key: const ValueKey('regStep0'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel("Agency Information"),
          const SizedBox(height: 14),
          _buildTextField(
            label: "Agency Name",
            controller: _agencyNameController,
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Owner / Manager Name",
            controller: _ownerNameController,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Work Email",
            controller: _agencyEmailController,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      );
    }

    // ── Step 2: Verify email (OTP)
    if (currentStep == 1) {
      return Column(
        key: const ValueKey('regStep1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel("Verify Your Email"),
          const SizedBox(height: 8),
          Text(
            "Enter the 4-digit code sent to\n${_agencyEmailController.text.isEmpty ? 'your email' : _agencyEmailController.text}",
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
            length: 4,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
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
    }

    // ── Step 3: Password (after email verification)
    return Column(
      key: const ValueKey('regStep2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel("Set Your Password"),
        const SizedBox(height: 8),
        Text(
          "Email verified ✓ — choose a secure password to finish creating your account.",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withOpacity(0.55),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Password
        _buildPasswordField(
          label: "Password",
          controller: _passwordController,
          obscure: _obscurePassword,
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),

        // Confirm Password
        _buildPasswordField(
          label: "Confirm Password",
          controller: _confirmPasswordController,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: Colors.white.withOpacity(0.45)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Use at least 6 characters, mixing letters and numbers.",
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButtons() {
    final isLast = currentStep == _totalSteps - 1;
    return Row(
      children: [
        if (currentStep > 0)
          Expanded(
            child: _buildOutlineButton(
              label: "Back",
              onPressed: () => setState(() => currentStep--),
            ),
          ),
        if (currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: currentStep > 0 ? 2 : 1,
          child: _buildPrimaryButton(
            label: isLast ? "Create Account" : "Next Step",
            onPressed: () {
              if (!_validateCurrentStep()) return;

              if (currentStep < _totalSteps - 1) {
                setState(() => currentStep++);
              } else {
                _handleComplete();
              }
            },
            icon: isLast
                ? Icons.check_circle_rounded
                : Icons.arrow_forward_rounded,
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
        final boxSize = (constraints.maxWidth - 3 * 14) / 4;
        final size = boxSize.clamp(44.0, 64.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i == length - 1 ? 0 : 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: size,
                height: size * 1.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: focusNodes[i].hasFocus
                        ? _accent
                        : Colors.white.withOpacity(0.15),
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.5), fontSize: 14),
        floatingLabelStyle: GoogleFonts.outfit(
            color: _accent, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white.withOpacity(0.4), size: 20)
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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

  /// Password-styled text field with a visibility toggle.
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.5), fontSize: 14),
        floatingLabelStyle: GoogleFonts.outfit(
            color: _accent, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: Colors.white.withOpacity(0.4), size: 20),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              colors: [Color(0xFFA855F7), Color(0xFF00F0FF)],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFF00F0FF)],
            )
                : null,
            color: isActive ? null : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: _accent.withOpacity(0.4),
                blurRadius: 12,
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              "$stepNum",
              style: GoogleFonts.outfit(
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.35),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 20,
      height: 2.5,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: isActive
            ? const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF00F0FF)],
        )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.12),
      ),
    );
  }
}