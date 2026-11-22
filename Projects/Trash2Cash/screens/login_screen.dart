import 'package:flutter/material.dart';
import '../services/api_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await ApiService.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result.success) {
      final userData = (result.data is Map<String, dynamic>)
          ? result.data as Map<String, dynamic>
          : {
              'username': _usernameController.text.trim(),
            };

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (_) => false,
        arguments: userData,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
            child: IntrinsicHeight(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          _buildLogo(),
                          const SizedBox(height: 48),
                          _buildUsernameField(),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text('Forgot Password?',
                                  style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLoginButton(),
                          const SizedBox(height: 24),
                          _buildRegisterLink(),
                          const Spacer(),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Center(child: Icon(Icons.recycling, color: Colors.white, size: 44)),
      ),
      const SizedBox(height: 16),
      ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]).createShader(bounds),
        child: const Text('Trash2Cash', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2)),
      ),
      const SizedBox(height: 4),
      Text('Turn waste into value', style: TextStyle(fontSize: 13, color: Colors.green.shade600, letterSpacing: 0.5)),
    ]);
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: _usernameController,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
        decoration: InputDecoration(
          hintText: 'Username', hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.person_outline, color: Colors.green.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
        decoration: InputDecoration(
          hintText: 'Password', hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade600),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4, shadowColor: Colors.green.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Don't have an account yet? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/register'),
        child: Text('Register', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 14,
            decoration: TextDecoration.underline, decorationColor: Colors.green.shade700)),
      ),
    ]);
  }

  Widget _buildFooter() {
    return Column(children: [
      Divider(color: Colors.green.shade200, thickness: 1),
      const SizedBox(height: 8),
      Text('Trash2Cash. All rights reserved.', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, letterSpacing: 0.3)),
    ]);
  }
}
