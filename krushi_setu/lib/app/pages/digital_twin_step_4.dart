import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';

class DigitalTwinStep4Screen extends StatefulWidget {
  const DigitalTwinStep4Screen({super.key});

  @override
  State<DigitalTwinStep4Screen> createState() => _DigitalTwinStep4ScreenState();
}

class _DigitalTwinStep4ScreenState extends State<DigitalTwinStep4Screen> {
  String _selectedLanguage = 'Kannada';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ',
    'English': 'A',
    'Hindi': 'अ',
    'Marathi': 'क्ष',
    'Tamil': 'அ',
    'Telugu': 'ఠ',
  };

  final Set<int> _selectedCrops = {
    0,
    5,
    8,
  }; // Pre-selecting Paddy, Pulses, Vegetables based on image

  final List<Map<String, dynamic>> _crops = [
    {
      'title': 'Paddy',
      'image': 'https://img.icons8.com/emoji/48/sheaf-of-rice.png',
    },
    {'title': 'Wheat', 'image': 'https://img.icons8.com/3d-fluency/94/wheat'},
    {
      'title': 'Ragi',
      'image':
          'https://img.icons8.com/external-glyphons-amoghdesign/64/external-grain-horse-riding-glyphons-amoghdesign.png',
    },
    {
      'title': 'Maize',
      'image': 'https://img.icons8.com/emoji/96/ear-of-corn.png',
    },
    {'title': 'Cotton', 'image': 'https://img.icons8.com/3d-fluency/94/cotton'},
    {
      'title': 'Sugarcane',
      'image':
          'https://img.icons8.com/external-others-pike-picture/50/external-candy-sugar-cane-agriculture-others-pike-picture.png',
    },
    {'title': 'Pulses', 'image': 'https://img.icons8.com/color/96/peas.png'},
    {
      'title': 'Groundnut',
      'image': 'https://img.icons8.com/emoji/96/peanuts-emoji.png',
    },
    {
      'title': 'Vegetables',
      'image': 'https://img.icons8.com/emoji/96/tomato-emoji.png',
    },
    {
      'title': 'Fruits',
      'image': 'https://img.icons8.com/emoji/96/mango-emoji.png',
    },
    {
      'title': 'Flowers',
      'image': 'https://img.icons8.com/3d-fluency/94/bunch-flowers.png',
    },
    {'title': 'Other', 'isOther': true},
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
                  _buildStep(3, 'Water', isActive: true, isCompleted: true),
                  _buildStepLine(isCompleted: true),
                  _buildStep(4, 'Crops', isActive: true),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area with text and background image
                    Stack(
                      children: [
                        // Text content
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 24.0,
                            right: 24.0,
                            top: 10,
                            bottom: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Step 4 of 4',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'What crops did you grow\nin the last season?',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'This helps us give better recommendations\nbased on your crop history.',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          SizedBox(height: 24),
                          const Text(
                            'Select the crops you grew',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Grid of Crops
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: _crops.length,
                            itemBuilder: (context, index) {
                              final item = _crops[index];
                              final isSelected = _selectedCrops.contains(index);
                              final isOther = item['isOther'] == true;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedCrops.contains(index)) {
                                      _selectedCrops.remove(index);
                                    } else {
                                      _selectedCrops.add(index);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFF2F7F4)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
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
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: isOther
                                                  ? const Center(
                                                      child: Icon(
                                                        Icons.more_horiz,
                                                        color:
                                                            AppColors.primary,
                                                        size: 28,
                                                      ),
                                                    )
                                                  : Center(
                                                      child: CachedNetworkImage(
                                                        alignment:
                                                            Alignment.center,
                                                        imageUrl: item['image'],
                                                        fit: BoxFit.contain,
                                                        width: 48,
                                                        height: 48,
                                                        placeholder: (context, url) => Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Color(
                                                                  0xFFF9F9F9,
                                                                ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: const Center(
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                      Color
                                                                    >(
                                                                      AppColors
                                                                          .primary,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => Container(
                                                              decoration:
                                                                  const BoxDecoration(
                                                                    color: Color(
                                                                      0xFFF9F9F9,
                                                                    ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                              child: const Center(
                                                                child: Icon(
                                                                  Icons.grass,
                                                                  color: Colors
                                                                      .grey,
                                                                  size: 24,
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                              left: 2,
                                              right: 2,
                                            ),
                                            child: Text(
                                              item['title'],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Checkmark / circle
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: AppColors.primary,
                                                size: 18,
                                              )
                                            : Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE0E0E0,
                                                    ),
                                                    width: 1,
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

                          // Don't see your crop card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F7F4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.eco_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Don't see your crop?",
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'You can add custom crops in your profile later.',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Additional notes
                          RichText(
                            text: const TextSpan(
                              text: 'Any additional notes? ',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '(Optional)',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Tap mic to speak or type here...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 14,
                              ),
                              suffixIcon: const Icon(
                                Icons.mic_none_outlined,
                                color: AppColors.textPrimary,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E5E5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E5E5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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
                    text: 'Complete Profile',
                    iconPosition: IconPosition.right,
                    onPressed: () {
                      // TODO: Navigate to completion or dashboard
                    },
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
