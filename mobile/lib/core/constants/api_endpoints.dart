/// Purpose: Centralized API Endpoints Configuration for Flutter App
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator localhost
  static const String webBaseUrl = 'http://localhost:5000/api';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String categories = '/categories';
  static const String credits = '/credits';
  static const String budgets = '/budgets';
  static const String analytics = '/analytics';
  static const String importCsv = '/transactions/import/csv';
  static const String exportCsv = '/transactions/export/csv';
}
