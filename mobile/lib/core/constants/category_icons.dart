import 'package:flutter/material.dart';

/// Purpose: Centralized Category Icons & Color Palette Helper
/// Author: Antigravity AI

class CategoryIconOption {
  final String key;
  final IconData icon;
  final String label;

  const CategoryIconOption({required this.key, required this.icon, required this.label});
}

class CategoryIcons {
  static const List<CategoryIconOption> availableIcons = [
    CategoryIconOption(key: 'restaurant', icon: Icons.restaurant_rounded, label: 'Food'),
    CategoryIconOption(key: 'shopping_cart', icon: Icons.shopping_cart_rounded, label: 'Shopping'),
    CategoryIconOption(key: 'directions_car', icon: Icons.directions_car_rounded, label: 'Transport'),
    CategoryIconOption(key: 'lightbulb', icon: Icons.lightbulb_rounded, label: 'Bills'),
    CategoryIconOption(key: 'movie', icon: Icons.movie_rounded, label: 'Entertainment'),
    CategoryIconOption(key: 'medical_services', icon: Icons.medical_services_rounded, label: 'Health'),
    CategoryIconOption(key: 'school', icon: Icons.school_rounded, label: 'Education'),
    CategoryIconOption(key: 'flight', icon: Icons.flight_rounded, label: 'Travel'),
    CategoryIconOption(key: 'attach_money', icon: Icons.attach_money_rounded, label: 'Salary'),
    CategoryIconOption(key: 'trending_up', icon: Icons.trending_up_rounded, label: 'Investment'),
    CategoryIconOption(key: 'subscriptions', icon: Icons.subscriptions_rounded, label: 'Subscription'),
    CategoryIconOption(key: 'home', icon: Icons.home_rounded, label: 'Housing'),
    CategoryIconOption(key: 'build', icon: Icons.build_rounded, label: 'Repair'),
    CategoryIconOption(key: 'coffee', icon: Icons.coffee_rounded, label: 'Cafe'),
    CategoryIconOption(key: 'phone_android', icon: Icons.phone_android_rounded, label: 'Mobile'),
    CategoryIconOption(key: 'pets', icon: Icons.pets_rounded, label: 'Pets'),
    CategoryIconOption(key: 'fitness_center', icon: Icons.fitness_center_rounded, label: 'Gym'),
    CategoryIconOption(key: 'redeem', icon: Icons.redeem_rounded, label: 'Gifts'),
  ];

  static const List<Color> availableColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFEF4444), // Crimson
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Blue
  ];

  static IconData getIcon(String? key) {
    if (key == null || key.isEmpty) return Icons.category_rounded;
    final found = availableIcons.firstWhere(
      (item) => item.key == key || item.label.toLowerCase() == key.toLowerCase(),
      orElse: () => const CategoryIconOption(key: 'category', icon: Icons.category_rounded, label: 'Category'),
    );
    return found.icon;
  }

  static Color parseColor(String? colorHex, {Color defaultColor = const Color(0xFF6366F1)}) {
    if (colorHex == null || colorHex.isEmpty) return defaultColor;
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }
}
