import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/pages/ask_krushi_screen.dart';
import 'package:krushi_setu/app/pages/blogs_screen.dart';
import 'package:krushi_setu/app/pages/profile_screen.dart';
import 'package:krushi_setu/app/pages/fields_screen.dart';
import 'package:krushi_setu/app/pages/market_prices_screen.dart';
import 'package:krushi_setu/app/services/user_service.dart';
import 'package:krushi_setu/app/widgets/custom_bottom_nav_bar.dart';
import 'package:krushi_setu/app/widgets/language_selector.dart';
import 'package:krushi_setu/app/services/weather_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _selectedLanguage = 'English';
  String _farmerName = 'Farmer';

  final WeatherService _weatherService = WeatherService();
  final UserService _userService = UserService();

  WeatherData? _weather;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _userService.fetchMyProfile();
      if (user != null && mounted) {
        setState(() {
          _farmerName = user.fullName;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadWeather() async {
    try {
      final data = await _weatherService.fetchWeather();
      if (mounted) {
        setState(() {
          _weather = data;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  Widget _buildBodyForTab() {
    switch (_currentIndex) {
      case 1:
        return FieldsScreen(
          onBackPressed: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        );
      case 2:
        return const BlogsScreen();
      case 3:
        return ProfileScreen(
          onNavigateToFields: () {
            setState(() {
              _currentIndex = 1;
            });
          },
          onBackPressed: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        );
      case 0:
      default:
        return Column(
          children: [
            // ── Fixed Header ──
            _buildHeader(),
            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildAiAssistantBanner(),
                      const SizedBox(height: 28),
                      _buildQuickAccess(),
                      const SizedBox(height: 28),
                      _buildWeatherCard(),
                      if (_weather != null &&
                          _weather!.dailyForecasts.isNotEmpty)
                        const SizedBox(height: 24),
                      if (_weather != null &&
                          _weather!.dailyForecasts.isNotEmpty)
                        _buildDailyForecastCard(),
                      const SizedBox(height: 20), // padding for bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: _buildBodyForTab(),
        ),
        extendBody: true,
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTabSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          onCenterActionTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const AskKrushiScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
          },
          isCenterActionActive: false,
        ),
      ),
    );
  }

  // ─── Fixed Header ───────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 14),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Image.asset('assets/logo_image.png', width: 45, height: 45),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $_farmerName!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome to Krushi Setu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          LanguageSelectorWidget(
            selectedLanguage: _selectedLanguage,
            onLanguageChanged: (value) {
              setState(() {
                _selectedLanguage = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ─── AI Assistant Banner ───────────────────────────────────

  Widget _buildAiAssistantBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AskKrushiScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('assets/images/dashboard_banner.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              right: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Your AI assistant',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ask Maya',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'About crops, pests, weather, soil and more',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Access ───────────────────────────────────────────

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlogsScreen()),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickAccessItem(
              icon: Icons.eco,
              title: 'Crop\nPlanner',
              bgColor: const Color(0xFFE8F5E9), // Light green
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlogsScreen(initialCategory: 'farming_tips')),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildQuickAccessItem(
              icon: Icons.menu_book,
              title: 'Knowledge\nBase',
              bgColor: const Color(0xFFE3F2FD), // Light blue
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlogsScreen(initialCategory: 'all')),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildQuickAccessItem(
              icon: Icons.account_balance,
              title: 'Schemes\n& Benefits',
              bgColor: const Color(0xFFFFF3E0), // Light orange
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlogsScreen(initialCategory: 'scheme')),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildQuickAccessItem(
              icon: Icons.currency_rupee,
              title: 'Market\nPrices',
              bgColor: const Color(0xFFF3E5F5), // Light purple
              iconColor: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketPricesScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String title,
    required Color bgColor,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 68,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 30)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Weather Card ──────────────────────────────────────────

  Widget _buildWeatherCard() {
    if (_isLoadingWeather) {
      return _buildWeatherShimmer();
    }
    if (_weather == null) {
      return const SizedBox.shrink();
    }
    final w = _weather!;
    final updatedAgo = DateTime.now().difference(w.lastUpdated).inMinutes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🌤️', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Today\'s Weather',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _isLoadingWeather = true);
                    _loadWeather();
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.refresh, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main weather info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Main weather info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${w.temperature.round()}°C',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SvgPicture.network(
                      w.conditionIcon,
                      width: 56,
                      height: 56,
                      placeholderBuilder: (context) =>
                          const Icon(Icons.cloud, size: 42),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        w.condition,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        w.locationName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      updatedAgo < 1
                          ? 'Just now'
                          : 'Updated $updatedAgo min ago',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Color(0xFFEEEEEE), height: 1),
                ),
                // Bottom section: Details Grid (3 items per row)
                Row(
                  children: [
                    Expanded(
                      child: _buildWeatherDetail(
                        'Feels like',
                        '${w.feelsLike.round()}°',
                        Icons.thermostat,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildWeatherDetail(
                        'Humidity',
                        '${w.humidity}%',
                        Icons.water_drop,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildWeatherDetail(
                        'Wind',
                        '${w.windSpeed.round()} km/h',
                        Icons.air,
                        Colors.lightBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildWeatherDetail(
                        'Rain',
                        '${w.rainChance}%',
                        Icons.umbrella,
                        Colors.indigo,
                      ),
                    ),
                    Expanded(
                      child: _buildWeatherDetail(
                        'UV',
                        '${w.uvIndex.round()}',
                        Icons.wb_sunny,
                        w.uvIndex >= 6 ? Colors.red : Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildWeatherDetail(
                        'Visibility',
                        '${w.visibility.round()} km',
                        Icons.visibility,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Hourly forecast
          if (w.hourlyForecasts.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (int i = 0; i < w.hourlyForecasts.length; i++) ...[
                        _buildHourlyForecast(w.hourlyForecasts[i]),
                        if (i < w.hourlyForecasts.length - 1)
                          const SizedBox(width: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(
    String label,
    String value,
    IconData iconData,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(iconData, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(HourlyForecast forecast) {
    return Column(
      children: [
        Text(
          forecast.time,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SvgPicture.network(
          forecast.conditionIcon,
          width: 36,
          height: 36,
          placeholderBuilder: (context) => const Icon(Icons.cloud, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          '${forecast.temperature.round()}°C',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecastCard() {
    if (_weather == null || _weather!.dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '7-Day Rain & Weather',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._weather!.dailyForecasts.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      d.dayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SvgPicture.network(
                    d.conditionIcon,
                    width: 32,
                    height: 32,
                    placeholderBuilder: (context) => const Icon(Icons.cloud, size: 20),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.water_drop,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${d.rainChance}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${d.maxTemp.round()}° / ${d.minTemp.round()}°',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeatherShimmer() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Loading weather...',
              style: TextStyle(color: Color(0xFF999999), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
