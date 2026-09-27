import 'package:flutter/material.dart';
import 'package:krushi_setu/app/models/user_model.dart';
import 'package:krushi_setu/app/services/user_service.dart';
import 'package:krushi_setu/core/storage/local_storage.dart';
import 'package:krushi_setu/app/pages/login_screen.dart';
import 'package:krushi_setu/app/widgets/language_selector.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToFields;

  const ProfileScreen({super.key, this.onNavigateToFields});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _user;
  bool _isLoading = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = await _userService.fetchMyProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
        if (user?.preferredLanguage == 'kn') {
          _selectedLanguage = 'Kannada';
        } else if (user?.preferredLanguage == 'hi') {
          _selectedLanguage = 'Hindi';
        } else {
          _selectedLanguage = 'English';
        }
      });
    }
  }

  void _showEditProfileDialog() {
    if (_user == null) return;
    final nameController = TextEditingController(text: _user!.fullName);
    final phoneController = TextEditingController(text: _user!.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final updated = await _userService.updateProfile(
                  fullName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                );
                if (updated != null && mounted) {
                  setState(() => _user = updated);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() async {
    await LocalStorage.clearTokens();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Farmer Profile & Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header Card
                  _buildProfileHeader(),

                  const SizedBox(height: 24),

                  // Digital Twin Summary Card
                  _buildDigitalTwinSummaryCard(),

                  const SizedBox(height: 24),

                  // Language & App Settings
                  _buildSettingsSection(),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Log Out of Krushi Setu',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _user?.fullName ?? 'Farmer User';
    final email = _user?.email ?? '';
    final phone = _user?.phoneNumber ?? 'Add Phone Number';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'F',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalTwinSummaryCard() {
    final dt = _user?.digitalTwin;
    final loc = dt?['location'] ?? {};
    final land = dt?['land_size'] ?? {};
    final crops = dt?['crops']?['crops'] as List? ?? [];
    final district = loc['district'] ?? 'Dharwad';
    final state = loc['state'] ?? 'Karnataka';
    final sizeVal = land['size_value'] ?? '2.5';
    final unit = land['unit'] ?? 'Acres';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.eco_rounded, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Farm Digital Twin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (widget.onNavigateToFields != null)
                TextButton.icon(
                  onPressed: widget.onNavigateToFields,
                  icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                  label: const Text('View Fields', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTwinStat('Location', '$district, $state'),
              _buildTwinStat('Land Size', '$sizeVal $unit'),
            ],
          ),
          if (crops.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Active Crops: ${crops.join(', ')}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTwinStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.language, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('App Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              LanguageSelectorWidget(
                selectedLanguage: _selectedLanguage,
                onLanguageChanged: (val) async {
                  setState(() => _selectedLanguage = val);
                  final langCode = val == 'Kannada' ? 'kn' : (val == 'Hindi' ? 'hi' : 'en');
                  await _userService.updateProfile(preferredLanguage: langCode);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
