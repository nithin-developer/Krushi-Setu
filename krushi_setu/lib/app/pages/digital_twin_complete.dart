import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';

class DigitalTwinCompleteScreen extends StatefulWidget {
  const DigitalTwinCompleteScreen({super.key});

  @override
  State<DigitalTwinCompleteScreen> createState() =>
      _DigitalTwinCompleteScreenState();
}

class _DigitalTwinCompleteScreenState extends State<DigitalTwinCompleteScreen> {
  String _selectedLanguage = 'English';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ',
    'English': 'A',
    'Hindi': 'अ',
    'Marathi': 'क्ष',
    'Tamil': 'அ',
    'Telugu': 'ఠ',
  };

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        body: Stack(
          children: [
            // Background Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/backgrounds/digi_twin_complete_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Language Selector at top right
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 20.0,
                                top: 16.0,
                              ),
                              child: _buildLanguageSelector(),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Farmer Image with Checkmark
                          _buildFarmerProfile(),

                          const SizedBox(height: 24),

                          // Title Texts
                          const Text(
                            'Profile created\nsuccessfully!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.0),
                            child: Text(
                              'Your Digital Twin is ready.\nWe will personalize your experience and\ngive you the best farming guidance.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF4A4A4A),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Summary Card
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: _buildSummaryCard(),
                          ),

                          const SizedBox(height: 20),

                          // What's Next Card
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: _buildWhatsNextCard(),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Button Area
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDashboardButton(),
                        const SizedBox(height: 16),
                        _buildPrivacyText(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedLanguage = value;
        });
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
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
    );
  }

  Widget _buildFarmerProfile() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/farmer_done.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -15,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F7F4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                const Text(
                  'Your Farm Profile Summary',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Rows
          _buildSummaryRow(
            iconWidget: const Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 20,
            ),
            iconBgColor: const Color(0xFFE8F5E9),
            title: 'Location',
            valueWidget: const Text(
              'Kaginahalli, Maddur Taluk,\nMandya District, Karnataka',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          _buildSummaryRow(
            iconWidget: CachedNetworkImage(
              imageUrl: 'https://img.icons8.com/color/96/field.png',
              width: 22,
              height: 22,
            ),
            iconBgColor: const Color(0xFFF5F5F5),
            title: 'Land Size',
            valueWidget: const Text(
              '1 - 2 Acres',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          _buildSummaryRow(
            iconWidget: CachedNetworkImage(
              imageUrl: 'https://img.icons8.com/3d-fluency/94/water.png',
              width: 22,
              height: 22,
            ),
            iconBgColor: const Color(0xFFF0F8FF),
            title: 'Water Source',
            valueWidget: const Text(
              'Borewell',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          _buildSummaryRow(
            iconWidget: CachedNetworkImage(
              imageUrl: 'https://img.icons8.com/emoji/48/sheaf-of-rice.png',
              width: 22,
              height: 22,
            ),
            iconBgColor: const Color(0xFFFFF8E1),
            title: 'Last Season Crops',
            valueWidget: Row(
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://img.icons8.com/emoji/48/sheaf-of-rice.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 4),
                CachedNetworkImage(
                  imageUrl: 'https://img.icons8.com/color/96/peas.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 4),
                CachedNetworkImage(
                  imageUrl:
                      'https://img.icons8.com/external-flaticons-flat-flat-icons/64/external-vegetables-vegan-and-vegetarian-flaticons-flat-flat-icons.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '+1 more',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required Widget iconWidget,
    required Color iconBgColor,
    required String title,
    required Widget valueWidget,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 130,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(child: valueWidget),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            color: Color(0xFFF0F0F0),
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }

  Widget _buildWhatsNextCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's Next?",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "We'll now recommend crops, tips and alerts based on your farm profile.",
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton() {
    return PrimaryButton(
      text: 'Go to Dashboard',
      iconPosition: IconPosition.right,
      onPressed: () {
        // TODO: Navigate to dashboard
      },
    );
  }

  Widget _buildPrivacyText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.verified_user,
            color: AppColors.primary,
            size: 14,
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
    );
  }
}
