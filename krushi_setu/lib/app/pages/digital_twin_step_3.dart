import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';
import 'package:krushi_setu/app/pages/digital_twin_step_4.dart';

class DigitalTwinStep3Screen extends StatefulWidget {
  const DigitalTwinStep3Screen({super.key});

  @override
  State<DigitalTwinStep3Screen> createState() => _DigitalTwinStep3ScreenState();
}

class _DigitalTwinStep3ScreenState extends State<DigitalTwinStep3Screen> {
  String _selectedLanguage = 'Kannada';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ',
    'English': 'A',
    'Hindi': 'अ',
    'Marathi': 'क्ष',
    'Tamil': 'அ',
    'Telugu': 'ఠ',
  };

  Set<int> _selectedWaterSources = {0};

  final List<Map<String, dynamic>> _waterSources = [
    {
      'title': 'Borewell',
      'subtitle': 'Groundwater from your farm borewell.',
      'image': 'assets/icons/borewell.png',
    },
    {
      'title': 'Canal',
      'subtitle': 'Water supplied through a canal.',
      'image': 'assets/icons/canal.png',
    },
    {
      'title': 'Rainfed',
      'subtitle': 'Farming depends mainly on rainfall.',
      'image': 'assets/icons/rain.png',
    },
    {
      'title': 'Well',
      'subtitle': 'Water from open well in the farm',
      'image': 'assets/icons/well.png',
    },
    {
      'title': 'Pond',
      'subtitle': 'Water from farm pond or reservoir',
      'image': 'assets/icons/pond.png',
    },
    {
      'title': 'Drips / Sprinklers',
      'subtitle': 'Using drip or sprinkler irrigation',
      'image': 'assets/icons/drip.png',
    },
  ];

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  _buildStep(1, 'Location', isActive: true, isCompleted: true),
                  _buildStepLine(isCompleted: true),
                  _buildStep(2, 'Land Size', isActive: true, isCompleted: true),
                  _buildStepLine(isCompleted: true),
                  _buildStep(3, 'Water', isActive: true),
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
                    // Header Area with text and image
                    Stack(
                      children: [
                        // Text content
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 100.0,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Step 3 of 4',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'What is your main\nwater source?',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'This helps us suggest the best\ncrops and irrigation advice.',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Map Image
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/borewell.png',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Select your main water sources (you can select multiple options)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid of Water Sources
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: _waterSources.length,
                      itemBuilder: (context, index) {
                        final item = _waterSources[index];
                        final isSelected = _selectedWaterSources.contains(index);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedWaterSources.contains(index)) {
                                _selectedWaterSources.remove(index);
                              } else {
                                _selectedWaterSources.add(index);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF2F7F4)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF0F0F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: [
                                if (!isSelected)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Image
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.asset(
                                              item['image'],
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: Colors.grey[100],
                                                    child: const Icon(
                                                      Icons.water,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Title
                                          Expanded(
                                            child: Text(
                                              item['title'],
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['subtitle'],
                                        style: const TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Checkmark or Unchecked circle
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 20,
                                        )
                                      : Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFE0E0E0),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Info Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'You can update this later from your profile settings.',
                              style: TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          builder: (context) => const DigitalTwinStep4Screen(),
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

  Widget _buildStep(
    int stepNumber,
    String title, {
    bool isActive = false,
    bool isCompleted = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? AppColors.primary
                : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber.toString(),
            style: TextStyle(
              color: isActive || isCompleted
                  ? Colors.white
                  : const Color(0xFF888888),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive || isCompleted
                ? AppColors.primary
                : const Color(0xFF888888),
            fontSize: 11,
            fontWeight: isActive || isCompleted
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({bool isCompleted = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
        height: 1.5,
        color: isCompleted ? AppColors.primary : const Color(0xFFE5E5E5),
      ),
    );
  }
}
