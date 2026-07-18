import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';

class DigitalTwinStep2Screen extends StatefulWidget {
  const DigitalTwinStep2Screen({super.key});

  @override
  State<DigitalTwinStep2Screen> createState() => _DigitalTwinStep2ScreenState();
}

class _DigitalTwinStep2ScreenState extends State<DigitalTwinStep2Screen> {
  String _selectedLanguage = 'Kannada';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ',
    'English': 'A',
    'Hindi': 'अ',
    'Marathi': 'क्ष',
    'Tamil': 'அ',
    'Telugu': 'ఠ',
  };

  int _selectedLandSizeIndex = 0;
  String _selectedUnit = 'Acre';

  final List<Map<String, dynamic>> _landSizes = [
    {'title': 'Less than', 'subtitle': '1 Acre', 'highlight': true},
    {'title': '1 - 2', 'subtitle': 'Acres', 'highlight': false},
    {'title': '2 - 5', 'subtitle': 'Acres', 'highlight': false},
    {'title': '5 - 10', 'subtitle': 'Acres', 'highlight': false},
    {'title': '10 - 20', 'subtitle': 'Acres', 'highlight': false},
    {'title': 'More than', 'subtitle': '20 Acres', 'highlight': false},
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
                  _buildStep(2, 'Land Size', isActive: true),
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
                      'Step 2 of 4',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'What is the size of your land?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This helps us give better crop and yield\nrecommendations.',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Map Image
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/land.png',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // The asset might already have the dashed lines and markers.
                        // We will add the text just in case.
                        const Text(
                          'Your Land',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Select your land size',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid of Land Sizes
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.5,
                          ),
                      itemCount: _landSizes.length,
                      itemBuilder: (context, index) {
                        final item = _landSizes[index];
                        final isSelected = _selectedLandSizeIndex == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedLandSizeIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF2F7F4)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF0F0F0),
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
                            child: Row(
                              children: [
                                // Isometric icon placeholder
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: _buildIsometricIcon(index),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize:
                                              item['highlight'] == true &&
                                                  !isSelected
                                              ? 13
                                              : 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item['subtitle'],
                                        style: TextStyle(
                                          color: const Color(0xFF666666),
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Or enter exact size',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Exact size input
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              border: Border.all(
                                color: const Color(0xFFF0F0F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.map_outlined,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Enter land size',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      if (val.isNotEmpty) {
                                        setState(() {
                                          _selectedLandSizeIndex =
                                              -1; // Deselect grid
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border(
                              top: BorderSide(color: Color(0xFFF0F0F0)),
                              bottom: BorderSide(color: Color(0xFFF0F0F0)),
                              right: BorderSide(color: Color(0xFFF0F0F0)),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value:
                                  [
                                    'Acre',
                                    'Hectare',
                                    'Sq ft',
                                    'Guntas',
                                    'Cents',
                                  ].contains(_selectedUnit)
                                  ? _selectedUnit
                                  : 'Acre',
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.textPrimary,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              items:
                                  [
                                    'Acre',
                                    'Hectare',
                                    'Sq ft',
                                    'Guntas',
                                    'Cents',
                                  ].map((String unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedUnit = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
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
                      // TODO: Navigate to next step
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

  Widget _buildIsometricIcon(int index) {
    // Generate different divisions based on index to mimic the image
    int divisions = 1;
    if (index >= 1 && index <= 2) divisions = 2; // 2x2 grid
    if (index >= 3) divisions = 3; // 3x3 grid

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? const Color(0xFF8BC34A)
            : const Color(0xFF7CB342),
        border: Border.all(color: const Color(0xFF558B2F), width: 1),
      ),
      child: divisions > 1
          ? GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: divisions,
              ),
              itemCount: divisions * divisions,
              itemBuilder: (context, i) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF558B2F),
                      width: 0.5,
                    ),
                  ),
                );
              },
            )
          : null,
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
