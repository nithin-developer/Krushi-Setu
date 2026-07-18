import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';
import 'package:krushi_setu/app/pages/digital_twin_step_2.dart';
class DigitalTwinStep1Screen extends StatefulWidget {
  const DigitalTwinStep1Screen({super.key});

  @override
  State<DigitalTwinStep1Screen> createState() => _DigitalTwinStep1ScreenState();
}

class _DigitalTwinStep1ScreenState extends State<DigitalTwinStep1Screen> {
  String _selectedLanguage = 'Kannada';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ',
    'English': 'A',
    'Hindi': 'अ',
    'Marathi': 'क्ष',
    'Tamil': 'அ',
    'Telugu': 'ఠ',
  };

  String? _selectedState = 'Karnataka';
  String? _selectedDistrict = 'Mandya';
  String? _selectedTaluk = 'Maddur';
  String? _selectedVillage = 'Kaginahalli';

  List<String> get _states => ['Karnataka', 'Maharashtra', 'Gujarat', 'Tamil Nadu', 'Kerala'];
  List<String> get _districts => ['Mandya', 'Mysuru', 'Hassan', 'Bengaluru', 'Tumakuru'];
  List<String> get _taluks => ['Maddur', 'Malavalli', 'Srirangapatna', 'Pandavapura', 'Krishnarajpet'];
  List<String> get _villages => ['Kaginahalli', 'Besagarahalli', 'Koppa', 'Mellahalli', 'Bharathinagara'];

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        body: Column(
          children: [
            // Top Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    // Language Selector
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      },
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          for (final lang in _languageIcons.keys)
                            PopupMenuItem<String>(
                              value: lang,
                              child: Text(
                                lang,
                                style: TextStyle(
                                  color: _selectedLanguage == lang
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: _selectedLanguage == lang
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                        ];
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _languageIcons[_selectedLanguage] ?? 'A',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedLanguage,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Stepper
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Row(
                children: [
                  _buildStep(1, 'Location', isActive: true),
                  _buildStepLine(),
                  _buildStep(2, 'Land Size'),
                  _buildStepLine(),
                  _buildStep(3, 'Water'),
                  _buildStepLine(),
                  _buildStep(4, 'Crops'),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1 of 4',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Where is your farm located?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This helps us provide localised advice\nand weather updates.',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Map Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/map.png',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Find my location button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2EFE5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find my location',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Use your device location to\nauto-fill your farm location',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Or select manually divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'or select manually',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Dropdowns
                    _buildDropdown(
                      context: context,
                      icon: Icons.map_outlined,
                      title: 'State',
                      value: _selectedState,
                      items: _states,
                      onChanged: (val) => setState(() => _selectedState = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      context: context,
                      icon: Icons.location_city_outlined,
                      title: 'District',
                      value: _selectedDistrict,
                      items: _districts,
                      onChanged: (val) => setState(() => _selectedDistrict = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      context: context,
                      icon: Icons.spa_outlined,
                      title: 'Taluk',
                      value: _selectedTaluk,
                      items: _taluks,
                      onChanged: (val) => setState(() => _selectedTaluk = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      context: context,
                      icon: Icons.home_outlined,
                      title: 'Village',
                      value: _selectedVillage,
                      items: _villages,
                      onChanged: (val) => setState(() => _selectedVillage = val),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Bottom Button Area
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(24, 16, 24, padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    iconPosition: IconPosition.right,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DigitalTwinStep2Screen(),
                        ),
                      );
                    },
                    text: 'Continue',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your data is private and secure',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int stepNumber, String title, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF888888),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : const Color(0xFF888888),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
        height: 1.5,
        color: const Color(0xFFE5E5E5),
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String? value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in items)
                            InkWell(
                              onTap: () {
                                onChanged(item);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(
                                  color: item == value ? const Color(0xFFE8F5E9) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: item == value ? AppColors.primary : AppColors.textPrimary,
                                        fontWeight: item == value ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    if (item == value)
                                      const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F7F4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Select $title',
                    style: TextStyle(
                      color: value != null ? AppColors.textPrimary : Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }
}

