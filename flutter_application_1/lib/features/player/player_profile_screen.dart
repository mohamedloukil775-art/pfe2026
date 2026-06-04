import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../data/services/auth_service_mock.dart';
import '../../data/services/players_service_mock.dart';
import '../../domain/models/app_user.dart';
import '../../domain/enums/user_role.dart';

class PlayerProfileScreen extends StatefulWidget {
  final AppUser currentUser;

  const PlayerProfileScreen({super.key, required this.currentUser});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  static const _lime = Color(0xFFC8F000);
  static const _darkBg = Color(0xFF080C14);
  static const _cardBg = Color(0xFF0F1621);

  final _authServiceMock = AuthServiceMock();
  final _playersServiceMock = PlayersServiceMock();

  late final TextEditingController _nameController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _showPasswordSection = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Uint8List? _selectedImageBytes;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.nom);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _profileImageUrl = widget.currentUser.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImageBytes == null) return;
    setState(() => _isLoading = true);
    try {
      final base64Image = 'data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}';
      await _authServiceMock.updatePhotoPath(
        email: widget.currentUser.email,
        photoPath: base64Image,
      );
      await _playersServiceMock.updatePlayerPhoto(widget.currentUser.id, base64Image);
      widget.currentUser.photoPath = base64Image;
      setState(() {
        _profileImageUrl = base64Image;
        _selectedImageBytes = null;
      });
      _showSuccess('Photo mise à jour !');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showError('Nom vide');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authServiceMock.updateName(
        email: widget.currentUser.email,
        newName: newName,
      );
      await _playersServiceMock.updatePlayerName(widget.currentUser.id, newName);
      _showSuccess('Nom mis à jour !');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showError('Champs requis');
      return;
    }
    if (newPass != confirm) {
      _showError('Mots de passe différents');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authServiceMock.changePassword(
        email: widget.currentUser.email,
        currentPassword: current,
        newPassword: newPass,
      );
      _showSuccess('Mot de passe changé !');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordSection = false);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser.role == UserRole.admin) {
      return const Center(child: Text('Admin non autorisé ici'));
    }

    return Stack(
      children: [
        Positioned(
          top: -30,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _lime.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -50,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00A8FF).withValues(alpha: 0.04),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 24),
              _buildCard(
                icon: Icons.person_outline_rounded,
                title: 'Informations',
                child: _buildNameSection(),
              ),
              const SizedBox(height: 16),
              _buildCard(
                icon: Icons.lock_outline_rounded,
                title: 'Sécurité',
                child: _buildPasswordSection(),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: _darkBg.withValues(alpha: 0.6),
            child: const Center(child: CircularProgressIndicator(color: _lime)),
          ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    ImageProvider? imageProvider;
    if (_selectedImageBytes != null) {
      imageProvider = MemoryImage(_selectedImageBytes!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('data:')) {
        final base64Str = _profileImageUrl!.split(',').last;
        imageProvider = MemoryImage(base64Decode(base64Str));
      } else {
        imageProvider = NetworkImage(_profileImageUrl!);
      }
    }

    final initial = widget.currentUser.nom.isNotEmpty
        ? widget.currentUser.nom[0].toUpperCase()
        : '?';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_lime, Color(0xFF00A8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF1A2535),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: _lime,
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _lime,
                      shape: BoxShape.circle,
                      border: Border.all(color: _darkBg, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Color(0xFF080C14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.currentUser.nom,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.currentUser.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          if (_selectedImageBytes != null) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadProfileImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: const Color(0xFF080C14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: const Text(
                'Enregistrer la photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lime.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: _lime.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _lime, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nom complet',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateName,
          style: ElevatedButton.styleFrom(
            backgroundColor: _lime,
            foregroundColor: const Color(0xFF080C14),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Mettre à jour',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _showPasswordSection = !_showPasswordSection),
          child: Row(
            children: [
              Text(
                _showPasswordSection
                    ? 'Masquer'
                    : 'Modifier le mot de passe',
                style: TextStyle(
                  color: _lime.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showPasswordSection
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _lime.withValues(alpha: 0.85),
                size: 18,
              ),
            ],
          ),
        ),
        if (_showPasswordSection) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _currentPasswordController,
            label: 'Mot de passe actuel',
            icon: Icons.lock_rounded,
            obscureText: _obscureCurrent,
            suffixIcon: _visibilityToggle(
              _obscureCurrent,
              () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _newPasswordController,
            label: 'Nouveau mot de passe',
            icon: Icons.lock_open_rounded,
            obscureText: _obscureNew,
            suffixIcon: _visibilityToggle(
              _obscureNew,
              () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmer',
            icon: Icons.check_circle_outline_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: _visibilityToggle(
              _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: _lime,
              foregroundColor: const Color(0xFF080C14),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Changer le mot de passe',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: _lime.withValues(alpha: 0.6), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _lime.withValues(alpha: 0.5), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _visibilityToggle(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: Colors.white38,
        size: 18,
      ),
      onPressed: onTap,
    );
  }
}
