import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final String condition;
  final String conditionIcon;
  final double uvIndex;
  final int rainChance;
  final double visibility;
  final String locationName;
  final DateTime lastUpdated;
  final List<HourlyForecast> hourlyForecasts;
  final List<DailyForecast> dailyForecasts;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.condition,
    required this.conditionIcon,
    required this.uvIndex,
    required this.rainChance,
    required this.visibility,
    required this.locationName,
    required this.lastUpdated,
    required this.hourlyForecasts,
    required this.dailyForecasts,
  });
}

class HourlyForecast {
  final String time;
  final double temperature;
  final int weatherCode;
  final String conditionIcon;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.conditionIcon,
  });
}

class DailyForecast {
  final String dayName;
  final double minTemp;
  final double maxTemp;
  final int rainChance;
  final String conditionIcon;

  DailyForecast({
    required this.dayName,
    required this.minTemp,
    required this.maxTemp,
    required this.rainChance,
    required this.conditionIcon,
  });
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  WeatherData? _cachedData;
  DateTime? _lastFetchTime;

  /// Returns cached data if it was fetched less than 10 minutes ago.
  WeatherData? get cachedData {
    if (_cachedData != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 10) {
        return _cachedData;
      }
    }
    return null;
  }

  Future<WeatherData> fetchWeather() async {
    // Return cache if fresh
    if (cachedData != null) return cachedData!;

    // Get location
    double lat = 12.5882; // Default: Maddur, Karnataka
    double lon = 77.0471;
    String locationName = 'Maddur Taluk, Mandya';

    // Get location with strict timeout
    try {
      await Future(() async {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
            ),
          ).timeout(const Duration(seconds: 4));
          lat = position.latitude;
          lon = position.longitude;

          // Reverse geocode
          try {
            final nomUrl = Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&zoom=10',
            );
            final geoResp = await http
                .get(nomUrl, headers: {'User-Agent': 'KrushiSetu/1.0'})
                .timeout(const Duration(seconds: 4));
            if (geoResp.statusCode == 200) {
              final geoData = json.decode(geoResp.body);
              final address = geoData['address'] ?? {};
              final village =
                  address['village'] ??
                  address['town'] ??
                  address['city'] ??
                  '';
              final district =
                  address['county'] ??
                  address['state_district'] ??
                  address['state'] ??
                  '';
              if (village.isNotEmpty || district.isNotEmpty) {
                locationName = [
                  village,
                  district,
                ].where((s) => s.isNotEmpty).join(', ');
              }
            }
          } catch (_) {
            // Keep default location name
          }
        }
      }).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint(
        'Location fetch timed out or failed: $e, using default location.',
      );
    }

    // Fetch weather from Open-Meteo
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'weather_code,wind_speed_10m,uv_index,visibility,precipitation_probability,is_day'
      '&hourly=temperature_2m,weather_code,is_day'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
      '&timezone=auto'
      '&forecast_days=7',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final current = data['current'];
    final hourly = data['hourly'];
    final daily = data['daily'];

    final int currentIsDay = (current['is_day'] as num).toInt();

    // Parse hourly forecasts (next 12 hours from now)
    final List<String> times = List<String>.from(hourly['time']);
    final List<double> temps = List<double>.from(
      (hourly['temperature_2m'] as List).map((e) => (e as num).toDouble()),
    );
    final List<int> codes = List<int>.from(hourly['weather_code']);
    final List<int> isDays = List<int>.from(hourly['is_day']);

    final now = DateTime.now();
    final currentHourIndex = times.indexWhere((t) {
      final dt = DateTime.parse(t);
      return dt.hour >= now.hour && dt.day == now.day;
    });

    final List<HourlyForecast> hourlyForecastsList = [];
    if (currentHourIndex >= 0) {
      for (
        int i = currentHourIndex;
        i < currentHourIndex + 12 && i < times.length;
        i++
      ) {
        final dt = DateTime.parse(times[i]);
        final label = i == currentHourIndex
            ? 'Now'
            : '${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)} ${dt.hour >= 12 ? 'PM' : 'AM'}';
        hourlyForecastsList.add(
          HourlyForecast(
            time: label,
            temperature: temps[i],
            weatherCode: codes[i],
            conditionIcon: _getWeatherIconUrl(codes[i], isDays[i] == 1),
          ),
        );
      }
    }

    // Parse daily forecasts
    final List<String> dailyTimes = List<String>.from(daily['time']);
    final List<int> dailyCodes = List<int>.from(daily['weather_code']);
    final List<double> minTemps = List<double>.from(
      (daily['temperature_2m_min'] as List).map((e) => (e as num).toDouble()),
    );
    final List<double> maxTemps = List<double>.from(
      (daily['temperature_2m_max'] as List).map((e) => (e as num).toDouble()),
    );
    final List<int> rainChances = List<int>.from(
      daily['precipitation_probability_max'],
    );

    final List<DailyForecast> dailyForecastsList = [];
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 1; i < dailyTimes.length; i++) {
      final dt = DateTime.parse(dailyTimes[i]);
      final dayName = i == 1 ? 'Tomorrow' : weekDays[dt.weekday - 1];
      dailyForecastsList.add(
        DailyForecast(
          dayName: dayName,
          minTemp: minTemps[i],
          maxTemp: maxTemps[i],
          rainChance: rainChances[i],
          conditionIcon: _getWeatherIconUrl(
            dailyCodes[i],
            true,
          ), // always show day icon for daily max
        ),
      );
    }

    final int wCode = (current['weather_code'] as num).toInt();
    final weatherData = WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: wCode,
      condition: _getWeatherCondition(wCode),
      conditionIcon: _getWeatherIconUrl(wCode, currentIsDay == 1),
      uvIndex: (current['uv_index'] as num).toDouble(),
      rainChance: current['precipitation_probability'] != null
          ? (current['precipitation_probability'] as num).toInt()
          : 0,
      visibility: current['visibility'] != null
          ? (current['visibility'] as num).toDouble() /
                1000 // Convert m to km
          : 10.0,
      locationName: locationName,
      lastUpdated: DateTime.now(),
      hourlyForecasts: hourlyForecastsList,
      dailyForecasts: dailyForecastsList,
    );

    _cachedData = weatherData;
    _lastFetchTime = DateTime.now();
    return weatherData;
  }

  static String _getWeatherCondition(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain Showers';
    if (code <= 86) return 'Snow Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  static String _getWeatherIconUrl(int code, bool isDay) {
    String iconName;

    switch (code) {
      // Clear
      case 0:
        iconName = isDay ? 'clear-day' : 'clear-night';
        break;

      // Mainly clear
      case 1:
        iconName = isDay ? 'clear-day' : 'clear-night';
        break;

      // Partly cloudy
      case 2:
        iconName = isDay ? 'partly-cloudy-day' : 'partly-cloudy-night';
        break;

      // Overcast
      case 3:
        iconName = isDay ? 'overcast-day' : 'overcast-night';
        break;

      // Fog
      case 45:
      case 48:
        iconName = isDay ? 'fog-day' : 'fog-night';
        break;

      // Drizzle
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        iconName = 'drizzle';
        break;

      // Rain
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        iconName = 'rain';
        break;

      // Snow
      case 71:
      case 73:
      case 75:
      case 77:
        iconName = 'snow';
        break;

      // Rain showers
      case 80:
      case 81:
      case 82:
        iconName = isDay
            ? 'partly-cloudy-day-rain'
            : 'partly-cloudy-night-rain';
        break;

      // Snow showers
      case 85:
      case 86:
        iconName = isDay
            ? 'partly-cloudy-day-snow'
            : 'partly-cloudy-night-snow';
        break;

      // Thunderstorm
      case 95:
        iconName = isDay ? 'thunderstorms-day' : 'thunderstorms-night';
        break;

      // Thunderstorm + hail
      case 96:
      case 99:
        iconName = isDay
            ? 'thunderstorms-day-rain'
            : 'thunderstorms-night-rain';
        break;

      default:
        iconName = isDay ? 'overcast-day' : 'overcast-night';
    }

    // return 'https://cdn.meteocons.com/latest/svg-static/fill/$iconName.svg';
    return 'https://cdn.meteocons.com/3.0.0-next.10/svg-static/fill/$iconName.svg';
  }

  /// UV risk label
  static String uvLabel(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }
}
