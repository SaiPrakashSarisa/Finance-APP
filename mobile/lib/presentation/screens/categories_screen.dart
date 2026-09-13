import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_icons.dart';
import '../providers/category_provider.dart';
import '../widgets/add_category_dialog.dart';

/// Purpose: Categories Management Screen with Tabs for Expense & Income
/// Author: Antigravity AI

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryModal(String defaultType) {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        initialType: defaultType,
        onCategoryCreated: (_) {
          ref.read(categoryProvider.notifier).fetchCategories();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

    final expenseCategories = categoryState.categories.where((c) => c.type == 'expense').toList();
    final incomeCategories = categoryState.categories.where((c) => c.type == 'income').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Categories',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryViolet,
          labelColor: AppColors.primaryViolet,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Expense Categories'),
            Tab(text: 'Income Categories'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryViolet,
        onPressed: () {
          final activeType = _tabController.index == 0 ? 'expense' : 'income';
          _showAddCategoryModal(activeType);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Category',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: categoryState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryViolet))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryGrid(expenseCategories, 'expense'),
                _buildCategoryGrid(incomeCategories, 'income'),
              ],
            ),
    );
  }

  Widget _buildCategoryGrid(List allCategories, String type) {
    final parentCategories = allCategories.where((c) => c.parentCategoryId == null).toList();

    if (parentCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No ${type.toLowerCase()} categories found',
              style: GoogleFonts.outfit(color: AppColors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryViolet),
              onPressed: () => _showAddCategoryModal(type),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Create First Category', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(categoryProvider.notifier).fetchCategories(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: parentCategories.length,
        itemBuilder: (context, index) {
          final parent = parentCategories[index];
          final children = allCategories.where((c) => c.parentCategoryId == parent.id).toList();
          final iconData = CategoryIcons.getIcon(parent.icon);
          final badgeColor = CategoryIcons.parseColor(parent.color);

          return Card(
            color: AppColors.surfaceContainer,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: badgeColor.withOpacity(0.2),
                child: Icon(iconData, color: badgeColor, size: 20),
              ),
              title: Text(
                parent.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                '${children.length} subcategories',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                    tooltip: 'Add Subcategory',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddCategoryDialog(
                          initialType: type,
                          initialParentCategoryId: parent.id,
                          onCategoryCreated: (_) {
                            ref.read(categoryProvider.notifier).fetchCategories();
                          },
                        ),
                      );
                    },
                  ),
                  const Icon(Icons.expand_more_rounded, color: AppColors.onSurfaceVariant),
                ],
              ),
              children: children.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'No subcategories added yet. Tap + to add one.',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      )
                    ]
                  : children.map((sub) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: AppColors.primaryViolet),
                            const SizedBox(width: 10),
                            Text(
                              sub.name,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          );
        },
      ),
    );
  }
}
