
import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart' show LandingCard, LandingLogo;
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/landing_colors.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final int initialTab;

  const LoginScreen({super.key, this.initialTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Sign-in controllers
  final _signInEmailCtrl = TextEditingController();
  final _signInPassCtrl = TextEditingController();

  // Registration controllers
  final _regUsernameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();

  // Password visibility
  bool _signInObscure = true;
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  // Validation and loading state
  bool _confirmMismatch = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tab.dispose();

    _signInEmailCtrl.dispose();
    _signInPassCtrl.dispose();

    _regUsernameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();

    super.dispose();
  }

  // ── Password Helpers ──────────────────────────────────────────────

  int _passwordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$&*~%^()_\-+=]'))) score++;

    return score;
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 1:
        return AppColors.rose;
      case 2:
        return AppColors.amber;
      case 3:
        return LandingColors.primary;
      case 4:
        return AppColors.emerald;
      default:
        return LandingColors.border;
    }
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  // ── Snackbar ──────────────────────────────────────────────────────

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: LandingColors.background,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
          side: BorderSide(
            color: isError
                ? AppColors.rose.withValues(alpha: 0.4)
                : AppColors.emerald.withValues(alpha: 0.4),
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: isError ? AppColors.rose : AppColors.emerald,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Sign In ───────────────────────────────────────────────────────

  Future<void> _submitSignIn() async {
    final email = _signInEmailCtrl.text.trim();
    final password = _signInPassCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar(
        'Please fill in all fields.',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Authenticate through the FastAPI backend.
      await ApiService.login(
        usernameOrEmail: email,
        password: password,
      );

      // Load the user's saved theme settings.
      await ThemeController.loadForCurrentUser();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackbar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ── Register ──────────────────────────────────────────────────────

  Future<void> _submitRegister() async {
    final username = _regUsernameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final password = _regPassCtrl.text;
    final confirm = _regConfirmPassCtrl.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showSnackbar(
        'Please fill in all fields.',
        isError: true,
      );
      return;
    }

    if (username.length < 3 || username.length > 50) {
      _showSnackbar(
        'Username must be 3–50 characters.',
        isError: true,
      );
      return;
    }

    if (password.length < 8) {
      _showSnackbar(
        'Password must be at least 8 characters.',
        isError: true,
      );
      return;
    }

    if (password != confirm) {
      setState(() => _confirmMismatch = true);
      return;
    }

    setState(() {
      _confirmMismatch = false;
      _loading = true;
    });

    try {
      // Create the account through the FastAPI backend.
      await ApiService.register(
        username: username,
        email: email,
        password: password,
      );

      // Load the user's saved theme settings.
      await ThemeController.loadForCurrentUser();

      if (!mounted) return;

      // Continue to the dashboard after successful registration.
      _openDashboard();
    } catch (e) {
      if (!mounted) return;

      _showSnackbar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────

  void _openDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
      (route) => false,
    );
  }

  // ── Main Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 24,
                24,
                compact ? 16 : 24,
                32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoLink(),
                    const SizedBox(height: 24),
                    LandingCard(
                      padding: EdgeInsets.all(compact ? 20 : 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildTabBar(),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _tab.index == 0
                                ? _buildSignInForm()
                                : _buildRegisterForm(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBackLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────

  Widget _buildLogoLink() {
    return Center(
      child: Tooltip(
        message: 'Back to home',
        child: InkWell(
          borderRadius: BorderRadius.circular(LandingRadius.control),
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: LandingLogo(),
          ),
        ),
      ),
    );
  }

  // ── Back Link ────────────────────────────────────────────────────

  Widget _buildBackLink() {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 16,
        ),
        label: const Text('Back to home'),
        style: TextButton.styleFrom(
          foregroundColor: LandingColors.textSecondary,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final signIn = _tab.index == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          signIn ? 'Welcome back' : 'Create an account',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          signIn
              ? 'Sign in to view your household electricity records.'
              : 'Register to start tracking your household electricity.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LandingColors.backgroundSoft,
        borderRadius: BorderRadius.circular(LandingRadius.control),
        border: Border.all(
          color: LandingColors.border,
        ),
      ),
      child: TabBar(
        controller: _tab,
        onTap: (_) {
          setState(() => _confirmMismatch = false);
        },
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: LandingColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: LandingColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Sign In'),
          Tab(text: 'Register'),
        ],
      ),
    );
  }

  // ── Sign In Form ──────────────────────────────────────────────────

  Widget _buildSignInForm() {
    return Column(
      key: const ValueKey('signin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          controller: _signInEmailCtrl,
          label: 'Email Address or Username',
          hint: 'Enter your email or username',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _signInPassCtrl,
          label: 'Password',
          obscure: _signInObscure,
          onToggle: () {
            setState(() => _signInObscure = !_signInObscure);
          },
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              foregroundColor: LandingColors.primary,
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildSubmitButton(
          label: 'Sign In',
          onPressed: _submitSignIn,
        ),
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 20),
        _buildSocialRow(),
        const SizedBox(height: 20),
        _buildSwitchPrompt(
          message: "Don't have an account?  ",
          action: 'Register',
          onTap: () => setState(() => _tab.animateTo(1)),
        ),
      ],
    );
  }

  // ── Register Form ─────────────────────────────────────────────────

  Widget _buildRegisterForm() {
    final strength = _passwordStrength(_regPassCtrl.text);

    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          controller: _regUsernameCtrl,
          label: 'Username',
          hint: 'Enter your username',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _regEmailCtrl,
          label: 'Email Address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _regPassCtrl,
          label: 'Password',
          obscure: _regObscure,
          onToggle: () {
            setState(() => _regObscure = !_regObscure);
          },
          onChanged: (_) => setState(() {}),
        ),
        if (_regPassCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildStrengthBar(strength),
        ],
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _regConfirmPassCtrl,
          label: 'Confirm Password',
          obscure: _regConfirmObscure,
          onToggle: () {
            setState(() {
              _regConfirmObscure = !_regConfirmObscure;
            });
          },
          isError: _confirmMismatch,
          errorText: 'Passwords do not match',
          onChanged: (_) {
            if (_confirmMismatch) {
              setState(() => _confirmMismatch = false);
            }
          },
        ),
        const SizedBox(height: 24),
        _buildSubmitButton(
          label: 'Create Account',
          onPressed: _submitRegister,
        ),
        const SizedBox(height: 20),
        _buildSwitchPrompt(
          message: 'Already have an account?  ',
          action: 'Sign In',
          onTap: () => setState(() => _tab.animateTo(0)),
        ),
      ],
    );
  }

  // ── Shared Text Field ─────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: LandingColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 18,
          color: LandingColors.textSecondary,
        ),
      ),
    );
  }

  // ── Shared Password Field ─────────────────────────────────────────

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    bool isError = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: TextStyle(
        color: LandingColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: LandingColors.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: LandingColors.textSecondary,
          ),
          splashRadius: 18,
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
          borderSide: BorderSide(
            color: isError
                ? AppColors.rose
                : LandingColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
          borderSide: BorderSide(
            color: isError
                ? AppColors.rose
                : LandingColors.primary,
            width: 1.5,
          ),
        ),
        errorText: isError ? errorText : null,
        errorStyle: const TextStyle(
          color: AppColors.rose,
          fontSize: 12,
        ),
      ),
    );
  }

  // ── Password Strength Bar ─────────────────────────────────────────

  Widget _buildStrengthBar(int strength) {
    final color = _strengthColor(strength);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < 3 ? 5 : 0,
                  ),
                  height: 3,
                  decoration: BoxDecoration(
                    color: index < strength
                        ? color
                        : LandingColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _strengthLabel(strength),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────

  Widget _buildSubmitButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LandingColors.primary,
          disabledBackgroundColor:
              LandingColors.primary.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LandingRadius.control),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: LandingColors.border,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: LandingColors.border,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // ── Social Buttons ─────────────────────────────────────────────────

  Widget _buildSocialRow() {
    return Row(
      children: [
        Expanded(
          child: _socialButton(
            'Google',
            Icons.g_mobiledata_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _socialButton(
            'GitHub',
            Icons.code_rounded,
          ),
        ),
      ],
    );
  }

  Widget _socialButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(
          color: LandingColors.border,
          width: 1.5,
        ),
        backgroundColor: LandingColors.background,
        foregroundColor: LandingColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
        ),
      ),
      icon: Icon(
        icon,
        size: 20,
        color: LandingColors.textSecondary,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Switch Prompt ─────────────────────────────────────────────────

  Widget _buildSwitchPrompt({
    required String message,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: TextStyle(
              color: LandingColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
