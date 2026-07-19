import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
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
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildStatusBanner(),
                  const SizedBox(height: 16),
                  _buildAiAssistantBanner(),
                  const SizedBox(height: 24),
                  _buildQuickAccess(),
                  const SizedBox(height: 24),
                  _buildWeatherCard(),
                  const SizedBox(height: 16),
                  _buildBottomCards(),
                  // const SizedBox(height: 24), // padding for bottom nav
                ],
              ),
            ),
          ),
        ),
        extendBody: true,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }



  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.person, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello, Ramesh!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Welcome to Krushi Setu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        _buildLanguageSelector(),
      ],
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

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'You are online',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'GPS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantBanner() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/dashboard_banner.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // If the image already contains the text and button, we can leave this empty.
      // But typically we overlay text. The user said "use this for assets". I will assume the asset is a background.
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 20,
            bottom: 20,
            right: 140, // leave space for farmer on right
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Your AI farming assistant',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask anything about\nyour farm',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Crops, pests, weather, soil,\nmarket prices and more.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mic, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Tap to speak',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 12),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAccessItem(
              iconUrl: 'https://img.icons8.com/color/96/plant-under-sun.png',
              title: 'Crop\nPlanner',
              bgColor: const Color(0xFFF2F7F4),
            ),
            _buildQuickAccessItem(
              iconUrl: 'https://img.icons8.com/color/96/book.png',
              title: 'Knowledge\nBase',
              bgColor: const Color(0xFFF0F8FF),
            ),
            _buildQuickAccessItem(
              iconUrl: 'https://img.icons8.com/color/96/museum.png',
              title: 'Schemes &\nBenefits',
              bgColor: const Color(0xFFFFF8E1),
            ),
            _buildQuickAccessItem(
              iconUrl: 'https://img.icons8.com/color/96/rupee.png',
              title: 'Market\nPrices',
              bgColor: const Color(0xFFF3E5F5),
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessItem({
    required String iconUrl,
    required String title,
    required Color bgColor,
  }) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 80,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: CachedNetworkImage(
              imageUrl: iconUrl,
              width: 48,
              height: 48,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: 'https://img.icons8.com/color/48/partly-cloudy-day--v1.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Today\'s Weather',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'View Forecast',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 10),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '32°',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 6.0),
                            child: Text(
                              'C',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          CachedNetworkImage(
                            imageUrl: 'https://img.icons8.com/color/96/partly-cloudy-day--v1.png',
                            width: 48,
                            height: 48,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Partly Cloudy',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF666666)),
                          const SizedBox(width: 4),
                          const Text(
                            'Maddur Taluk, Mandya',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.refresh, size: 14, color: Color(0xFF999999)),
                          const SizedBox(width: 4),
                          const Text(
                            'Updated 10 min ago',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 100,
                  color: const Color(0xFFEEEEEE),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildWeatherDetail('Feels like', '36°C', 'https://img.icons8.com/color/48/thermometer.png')),
                            Expanded(child: _buildWeatherDetail('Humidity', '60%', 'https://img.icons8.com/color/48/water.png')),
                            Expanded(child: _buildWeatherDetail('Wind', '12 km/h', 'https://img.icons8.com/color/48/wind.png')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildWeatherDetail('Rain Chance', '20%', 'https://img.icons8.com/color/48/rain.png')),
                            Expanded(child: _buildWeatherDetail('UV Index', '7\nHigh', 'https://img.icons8.com/color/48/sun.png', isHigh: true)),
                            Expanded(child: _buildWeatherDetail('Visibility', '10 km', 'https://img.icons8.com/color/48/visible.png')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE)),
                bottom: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHourlyForecast('Now', '32°C', 'https://img.icons8.com/color/48/partly-cloudy-day--v1.png'),
                _buildHourlyForecast('11 AM', '33°C', 'https://img.icons8.com/color/48/partly-cloudy-day--v1.png'),
                _buildHourlyForecast('12 PM', '34°C', 'https://img.icons8.com/color/48/sun.png'),
                _buildHourlyForecast('1 PM', '35°C', 'https://img.icons8.com/color/48/sun.png'),
                _buildHourlyForecast('2 PM', '34°C', 'https://img.icons8.com/color/48/partly-cloudy-day--v1.png'),
                _buildHourlyForecast('3 PM', '33°C', 'https://img.icons8.com/color/48/cloud.png'),
                _buildHourlyForecast('4 PM', '32°C', 'https://img.icons8.com/color/48/rain.png'),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weather Advisory',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Light rain expected on Saturday. Plan your irrigation accordingly.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFF999999), size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, String iconUrl, {bool isHigh = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CachedNetworkImage(imageUrl: iconUrl, width: 14, height: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHigh ? Colors.orange : AppColors.textPrimary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(String time, String temp, String iconUrl) {
    return Column(
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        CachedNetworkImage(imageUrl: iconUrl, width: 24, height: 24),
        const SizedBox(height: 6),
        Text(
          temp,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://img.icons8.com/color/96/plant-under-sun.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Crop Advisory',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Apply organic manure in standing crops to improve soil health.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF555555),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'View Advisory',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_download, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Works Offline',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Some features are available offline.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF555555),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'View Offline Data',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
      height: 98,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF164720),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home, Icons.home_outlined, 'Home', 0),
                _buildNavItem(Icons.eco, Icons.eco_outlined, 'Fields', 1),
                const SizedBox(width: 56), // Space for center floating button
                _buildNavItem(Icons.description, Icons.description_outlined, 'Document', 2),
                _buildNavItem(Icons.person, Icons.person_outline, 'Profile', 3),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: _buildCenterAction(),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterAction() {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData selectedIcon, IconData unselectedIcon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? Colors.white : Colors.white60,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
