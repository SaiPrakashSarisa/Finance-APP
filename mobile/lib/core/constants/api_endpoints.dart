import 'package:flutter/foundation.dart';

/// Purpose: Centralized API Endpoints Configuration for Flutter App
/// Author: Antigravity AI

class ApiEndpoints {
  // Production Render Backend URL
  static const String productionBaseUrl = 'https://finance-app-axlj.onrender.com/api';

  // Development Base URLs
  static const String localBaseUrl = 'http://localhost:5001/api'; // iOS Simulator, Web, ADB reverse
  static const String physicalDeviceBaseUrl = 'http://192.168.1.5:5001/api'; // Physical Phone on Local Wi-Fi
  static const String emulatorBaseUrl = 'http://10.0.2.2:5001/api'; // Android Emulator

  // Explicit override via --dart-define=API_BASE_URL=...
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Resolves the active base URL automatically:
  /// - If an explicit `--dart-define=API_BASE_URL=...` is passed, it takes precedence.
  /// - When building for production (release APK / bundle), it automatically uses [productionBaseUrl].
  /// - When building for development (debug mode / flutter run), it automatically uses [localBaseUrl].
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _normalizeUrl(_envBaseUrl);
    }
    if (kReleaseMode) {
      return productionBaseUrl;
    }
    return localBaseUrl;
  }

  static String _normalizeUrl(String url) {
    if (url.endsWith('/api')) {
      return url;
    } else if (url.endsWith('/')) {
      return '${url}api';
    } else {
      return '$url/api';
    }
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // User Profile & Settings
  static const String profile = '/user/profile';
  static const String settings = '/user/settings';
  static const String changePassword = '/user/change-password';

  // Accounts
  static const String accounts = '/accounts';

  // Categories
  static const String categories = '/categories';

  // Transactions
  static const String transactions = '/transactions';
  static const String exportCsv = '/transactions/export/csv';
  static const String importCsv = '/transactions/import/csv';

  // Credits / Debt Tracker
  static const String credits = '/credits';
  static const String creditTotals = '/credits/totals';

  // Budgets
  static const String budgets = '/budgets';

  // Analytics
  static const String analyticsDashboard = '/analytics/dashboard';
  static const String analyticsCategories = '/analytics/categories';
  static const String analyticsMonthlyTrend = '/analytics/monthly-trend';
  static const String analyticsInsights = '/analytics/insights';
  static const String analyticsItemTrends = '/analytics/items/trends';
  static const String analyticsInflation = '/analytics/inflation';
  static const String analyticsMerchants = '/analytics/merchants';
  static const String analyticsMerchantCompare = '/analytics/merchants/compare';
  static const String analyticsSubscriptions = '/analytics/subscriptions';

  // Master Items
  static const String masterItemsLookup = '/master-items/lookup';
}
