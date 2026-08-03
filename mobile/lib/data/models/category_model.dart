/// Purpose: Category Data Model
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

class CategoryModel {
  final String id;
  final String name;
  final String type;
  final String? parentCategoryId;
  final String? color;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.parentCategoryId,
    this.color,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      parentCategoryId: json['parentCategoryId'] is Map
          ? json['parentCategoryId']['_id']
          : json['parentCategoryId'],
      color: json['color'] ?? '#6366f1',
      icon: json['icon'] ?? 'folder',
    );
  }
}
