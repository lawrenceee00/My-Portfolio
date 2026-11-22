import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_services.dart';

/// Formats input text so the first letter of each word is capitalized
/// (e.g. "juan dela cruz" -> "Juan Dela Cruz") while typing.
class _CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (final char in text.characters) {
      if (char.trim().isEmpty) {
        // whitespace — keep as is, next letter should be capitalized
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }

    final formatted = buffer.toString();

    // Try to keep the cursor at the same relative position.
    final selectionIndex = newValue.selection.end.clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedGender;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Must be ticked before the user is allowed to register.
  bool _agreedToTerms = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

    void _handleRegister() async {
    // Safety net: block registration until the user agrees to the terms.
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms of Use and Privacy Policy to continue.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Register, then log in automatically with the same credentials.
    final result = await ApiService.registerAndLogin(
      username:   _usernameController.text.trim(),
      firstname:  _firstNameController.text.trim(),
      lastname:   _lastNameController.text.trim(),
      middlename: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
      gender:     _selectedGender,
      contact:    _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      address:    _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      email:      _emailController.text.trim(),
      password:   _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.data is Map) {
      // Real user record from the server (includes id / userID).
      final userData = Map<String, dynamic>.from(result.data as Map);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Scan the machine QR to get started.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      // Straight to the dashboard on the QR tab, no login screen.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (_) => false,
        arguments: {
          ...userData,
          'openQr': true,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red.shade700),
      );

      // Account was created but auto-login failed -> normal login screen.
      if (result.message == 'Account created. Please log in.') {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(context),
                          const SizedBox(height: 28),
                          _buildFormCard(),
                          const SizedBox(height: 16),
                          _buildAgreementCheckbox(),
                          const SizedBox(height: 20),
                          _buildRegisterButton(),
                          const SizedBox(height: 16),
                          _buildLoginLink(context),
                          const SizedBox(height: 32),
                          _buildFooter(),
                          const SizedBox(height: 32),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.recycling, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]).createShader(bounds),
            child: const Text('Trash2Cash', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
          ),
        ]),
        Text('Create your account', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    ]);
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Account Info'),
        const SizedBox(height: 10),
        _buildField(
          controller: _usernameController,
          hint: 'Username',
          icon: Icons.alternate_email_rounded,
          inputFormatters: [_CapitalizeWordsFormatter()],
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Username required' : null,
        ),
        const SizedBox(height: 20),
        _sectionLabel('Personal Details'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _buildField(
              controller: _lastNameController,
              hint: 'Last name',
              icon: Icons.badge_outlined,
              inputFormatters: [_CapitalizeWordsFormatter()],
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildField(
              controller: _firstNameController,
              hint: 'First name',
              icon: Icons.person_outline,
              inputFormatters: [_CapitalizeWordsFormatter()],
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _buildField(
          controller: _middleNameController,
          hint: 'Middle name (optional)',
          icon: Icons.drive_file_rename_outline,
          inputFormatters: [_CapitalizeWordsFormatter()],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildGenderDropdown()),
          const SizedBox(width: 10),
          Expanded(
            child: _buildField(
              controller: _contactController,
              hint: 'Contact no.',
              icon: Icons.phone_outlined,
              inputType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && v.trim().length != 11) {
                  return 'Must be 11 digits';
                }
                return null;
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _buildField(
          controller: _addressController,
          hint: 'Address',
          icon: Icons.location_on_outlined,
          inputFormatters: [_CapitalizeWordsFormatter()],
        ),
        const SizedBox(height: 20),
        _sectionLabel('Security'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined,
              inputType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Invalid email';
                return null;
              })),
          const SizedBox(width: 10),
          Expanded(child: _buildPasswordField()),
        ]),
      ]),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade700, letterSpacing: 0.8));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEDDC)),
      ),
      child: TextFormField(
        controller: controller, keyboardType: inputType,
        validator: validator,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.green.shade500, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          isDense: true,
          counterText: maxLength != null ? '' : null,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEDDC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          hint: Row(children: [
            Icon(Icons.wc_outlined, color: Colors.green.shade500, size: 18),
            const SizedBox(width: 6),
            Text('Gender', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ]),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.green.shade400, size: 18),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEDDC)),
      ),
      child: TextFormField(
        controller: _passwordController, obscureText: _obscurePassword,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (v.length < 6) return 'Min 6 chars';
          return null;
        },
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Password', hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade500, size: 18),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400, size: 16),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          isDense: true,
        ),
      ),
    );
  }

  /// Required "I agree" checkbox. The Create Account button stays disabled
  /// until this is ticked.
  Widget _buildAgreementCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            activeColor: const Color(0xFF2E7D32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              children: [
                Text(
                  'I have read and agree to the ',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
                GestureDetector(
                  onTap: () => _showPolicyDialog(
                    'Terms of Use',
                    _termsText,
                  ),
                  child: Text(
                    'Terms of Use',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' and ',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
                GestureDetector(
                  onTap: () => _showPolicyDialog(
                    'Privacy Policy',
                    _privacyText,
                  ),
                  child: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' of Trash2Cash.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NOTE: Sample text only. Replace with your actual Terms of Use and
  // Privacy Policy before releasing the app.
  static const String _termsText =
      'By creating a Trash2Cash account, you agree to:\n\n'
      '1. Provide accurate and complete registration information.\n\n'
      '2. Keep your login details confidential and be responsible for all '
      'activity under your account.\n\n'
      '3. Use Trash2Cash machines only for accepted recyclables (PET bottles '
      'and aluminum cans) and not tamper with, damage, or abuse the machines '
      'or the app.\n\n'
      '4. Accept that points are earned only from items accepted by the '
      'machine, and that fraudulent or abusive activity may lead to point '
      'removal or account suspension.\n\n'
      '5. Accept that these terms may be updated from time to time.';

  static const String _privacyText =
      'Trash2Cash collects and uses your personal information to create and '
      'manage your account and recycling rewards.\n\n'
      'Information we collect:\n'
      '- Name, username, email, and password\n'
      '- Gender, contact number, and address (if provided)\n'
      '- Machine session and deposit records (items accepted and points '
      'earned)\n\n'
      'How we use it:\n'
      '- To register and identify you\n'
      '- To record your deposits and compute your points\n'
      '- To improve the Trash2Cash service\n\n'
      'We keep your information secure and do not sell it to third parties. '
      'You may request access to, correction of, or deletion of your data by '
      'contacting the Trash2Cash administrators.';

  void _showPolicyDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _agreedToTerms = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('I Agree'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    // Disabled while loading OR until the user agrees to the terms.
    final bool canRegister = _agreedToTerms && !_isLoading;

    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: canRegister ? _handleRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4, shadowColor: Colors.green.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text('Login', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 14,
            decoration: TextDecoration.underline, decorationColor: Colors.green.shade700)),
      ),
    ]);
  }

  Widget _buildFooter() {
    return Column(children: [
      Divider(color: Colors.green.shade200, thickness: 1),
      const SizedBox(height: 8),
      Text('Trash2Cash. All rights reserved.', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, letterSpacing: 0.3), textAlign: TextAlign.center),
    ]);
  }
}