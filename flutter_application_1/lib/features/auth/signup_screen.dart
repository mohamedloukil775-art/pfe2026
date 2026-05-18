import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../domain/domain.dart';
import '../../data/services/services.dart';
import '../admin/admin_home_screen.dart';
import '../player/player_home_screen.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onLoginTap;

  const SignupScreen({super.key, this.onLoginTap});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  static const _lime = Color(0xFFC8F000);
  static const _darkBg = Color(0xFF080C14);
  static const _cardBg = Color(0xFF0F1621);
  static const _blue = Color(0xFF00A8FF);

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthServiceMock();
  final _playersService = PlayersServiceMock();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _photoPath;
  int _niveauSelected = 3;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _photoPath = result.files.first.path);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors du chargement de la photo');
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final password = _passwordController.text;

      final user = await _authService.signup(
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        password: password,
        confirmPassword: _confirmPasswordController.text,
        niveau: _niveauSelected,
      );

      if (!mounted) return;

      await _playersService.createPlayer(
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        password: password,
        niveau: _niveauSelected,
        photoPath: _photoPath,
        clubId: 1,
      );

      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (user.role == UserRole.admin) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => PlayerHomeScreen(userId: user.id)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('ApiException: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // Background decorative orbs
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lime.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Logo + brand (identique au login)
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _lime,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: _lime.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_tennis_rounded,
                                size: 44,
                                color: Color(0xFF080C14),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'PADEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: _lime,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CHAMPIONSHIP',
                                style: TextStyle(
                                  color: Color(0xFF080C14),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Card form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Créer mon compte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rejoins la plateforme Padel Championship',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
                            ),
                            const SizedBox(height: 24),

                            // Photo picker – petit cercle centré
                            Center(
                              child: GestureDetector(
                                onTap: _isLoading ? null : _pickPhoto,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.04),
                                        border: Border.all(
                                          color: _photoPath != null
                                              ? _lime
                                              : Colors.white.withValues(alpha: 0.15),
                                          width: 2,
                                        ),
                                      ),
                                      child: _photoPath != null
                                          ? ClipOval(
                                              child: Image.file(
                                                File(_photoPath!),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 44,
                                              color: Colors.white.withValues(alpha: 0.3),
                                            ),
                                    ),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _lime,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Color(0xFF080C14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Nom complet
                            _SignupField(
                              controller: _nomController,
                              label: 'Nom complet',
                              icon: Icons.person_rounded,
                              enabled: !_isLoading,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                            ),

                            const SizedBox(height: 16),

                            // Email
                            _SignupField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email requis';
                                if (!v.contains('@')) return 'Email invalide';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Niveau dropdown stylisé
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    size: 20,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: _niveauSelected,
                                        isExpanded: true,
                                        dropdownColor: _cardBg,
                                        style: const TextStyle(color: Colors.white, fontSize: 15),
                                        hint: Text(
                                          'Niveau',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.45),
                                          ),
                                        ),
                                        items: List.generate(
                                          10,
                                          (i) => DropdownMenuItem(
                                            value: i + 1,
                                            child: Text('Niveau ${i + 1}'),
                                          ),
                                        ),
                                        onChanged: !_isLoading
                                            ? (value) =>
                                                setState(() => _niveauSelected = value ?? 3)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Mot de passe
                            _SignupField(
                              controller: _passwordController,
                              label: 'Mot de passe',
                              icon: Icons.lock_rounded,
                              obscureText: _obscurePassword,
                              enabled: !_isLoading,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Mot de passe requis';
                                if (v.length < 6) return 'Minimum 6 caractères';
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Confirmer le mot de passe
                            _SignupField(
                              controller: _confirmPasswordController,
                              label: 'Confirmer le mot de passe',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirmPassword,
                              enabled: !_isLoading,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Confirmation requise';
                                if (v != _passwordController.text) {
                                  return 'Les mots de passe ne correspondent pas';
                                }
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Bouton créer compte
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _lime,
                                  foregroundColor: const Color(0xFF080C14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF080C14),
                                        ),
                                      )
                                    : const Text(
                                        'CRÉER MON COMPTE',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lien connexion
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tu as déjà un compte ?  ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: _isLoading ? null : widget.onLoginTap,
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                color: Color(0xFFC8F000),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
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

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
