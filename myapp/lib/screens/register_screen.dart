import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../models/app_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final Set<String> _touched = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int _passwordStrength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
    return score;
  }

  Color _strengthColor(int score) {
    switch (score) {
      case 1: return const Color(0xFFE53935);
      case 2: return const Color(0xFFF57C00);
      case 3: return const Color(0xFFFFB300);
      case 4: return const Color(0xFF2D6A4F);
      default: return const Color(0xFFDDDDDD);
    }
  }

  String _strengthLabel(int score) {
    switch (score) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  void _submit() async {
    setState(() => _touched
        .addAll(['name', 'business', 'phone', 'email', 'password', 'confirm']));
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please agree to the Terms & Conditions to continue.'),
        backgroundColor: const Color(0xFFE8572A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // ── Save to AppStore ──────────────────────────────────────────────────
    final account = AppStore.instance.register(
      fullName: _nameCtrl.text.trim(),
      businessName: _businessCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            const Text('Account Created!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Welcome, ${_nameCtrl.text.trim().split(' ').first}!\n'
              '"${_businessCtrl.text.trim()}" is ready.\n\n'
              'Your username is: ${account.username}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8572A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Go to Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFAAAAAA), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8572A), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _sectionHeader(String emoji, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF444444),
                  letterSpacing: 0.3)),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0xFFEEECE8))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_passwordCtrl.text);

    return Scaffold(
      backgroundColor: const Color(0xFFE8572A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text('TindaHan',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Georgia',
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Text(' 🏪', style: TextStyle(fontSize: 18)),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Account',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Georgia')),
                      SizedBox(height: 4),
                      Text('Set up your store in seconds',
                          style: TextStyle(
                              color: Color(0xFFFFD4C2), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8F5),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('👤', 'Personal Information'),
                            TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDeco(
                                  label: 'Full Name',
                                  hint: 'e.g. Maria Santos',
                                  icon: Icons.person_outline_rounded),
                              onChanged: (_) => setState(() => _touched.add('name')),
                              validator: (v) {
                                if (!_touched.contains('name')) return null;
                                if (v == null || v.trim().isEmpty) return 'Full name is required';
                                if (v.trim().split(' ').length < 2) return 'Please enter first and last name';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDeco(
                                  label: 'Phone Number',
                                  hint: 'e.g. 09171234567',
                                  icon: Icons.phone_outlined),
                              onChanged: (_) => setState(() => _touched.add('phone')),
                              validator: (v) {
                                if (!_touched.contains('phone')) return null;
                                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                                if (v.trim().length < 10) return 'Enter a valid phone number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDeco(
                                  label: 'Email Address',
                                  hint: 'e.g. maria@email.com',
                                  icon: Icons.email_outlined),
                              onChanged: (_) => setState(() => _touched.add('email')),
                              validator: (v) {
                                if (!_touched.contains('email')) return null;
                                if (v == null || v.trim().isEmpty) return 'Email is required';
                                final re = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                                if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _sectionHeader('🏪', 'Business Information'),
                            TextFormField(
                              controller: _businessCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDeco(
                                  label: 'Business / Store Name',
                                  hint: "e.g. Maria's Sari-Sari Store",
                                  icon: Icons.storefront_outlined),
                              onChanged: (_) => setState(() => _touched.add('business')),
                              validator: (v) {
                                if (!_touched.contains('business')) return null;
                                if (v == null || v.trim().isEmpty) return 'Business name is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _sectionHeader('🔒', 'Account Security'),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() => _touched.add('password')),
                              decoration: _inputDeco(
                                label: 'Create Password',
                                hint: 'Minimum 8 characters',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFFAAAAAA),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (!_touched.contains('password')) return null;
                                if (v == null || v.isEmpty) return 'Password is required';
                                if (v.length < 8) return 'Password must be at least 8 characters';
                                return null;
                              },
                            ),
                            if (_passwordCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: strength / 4,
                                      minHeight: 5,
                                      backgroundColor: const Color(0xFFEEECE8),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _strengthColor(strength)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(_strengthLabel(strength),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _strengthColor(strength))),
                              ]),
                              const SizedBox(height: 4),
                              const Text(
                                  'Use uppercase, numbers & symbols for a stronger password',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFFAAAAAA))),
                            ],
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              onChanged: (_) => setState(() => _touched.add('confirm')),
                              decoration: _inputDeco(
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                icon: Icons.lock_reset_outlined,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFFAAAAAA),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (!_touched.contains('confirm')) return null;
                                if (v == null || v.isEmpty) return 'Please confirm your password';
                                if (v != _passwordCtrl.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // Terms
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _agreedToTerms = !_agreedToTerms),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _agreedToTerms
                                      ? const Color(0xFFE8F5EE)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _agreedToTerms
                                        ? const Color(0xFF2D6A4F)
                                        : const Color(0xFFDDDDDD),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _agreedToTerms
                                            ? const Color(0xFF2D6A4F)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _agreedToTerms
                                              ? const Color(0xFF2D6A4F)
                                              : const Color(0xFFCCCCCC),
                                          width: 2,
                                        ),
                                      ),
                                      child: _agreedToTerms
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'I agree to the ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF555555)),
                                          children: [
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: TextStyle(
                                                  color: Color(0xFFE8572A),
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.underline),
                                            ),
                                            TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                  color: Color(0xFFE8572A),
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.underline),
                                            ),
                                            TextSpan(
                                                text: ' of TindaHan. Your data will be kept safe and secure.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8572A),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFFE8572A).withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.storefront_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text('Create My Account',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text.rich(
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                        fontSize: 13, color: Color(0xFF888888)),
                                    children: [
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                            color: Color(0xFFE8572A),
                                            fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }
}
