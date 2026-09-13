import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_icons.dart';
import '../providers/category_provider.dart';

/// Purpose: Add New Category Modal Dialog Component
/// Author: Antigravity AI

class AddCategoryDialog extends ConsumerStatefulWidget {
  final String initialType;
  final String? initialParentCategoryId;
  final Function(String categoryId)? onCategoryCreated;

  const AddCategoryDialog({
    super.key,
    this.initialType = 'expense',
    this.initialParentCategoryId,
    this.onCategoryCreated,
  });

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _nameController = TextEditingController();
  late String _selectedType;
  String? _selectedParentCategoryId;
  String _selectedIconKey = 'shopping_cart';
  Color _selectedColor = CategoryIcons.availableColors[0];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedParentCategoryId = widget.initialParentCategoryId;
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';

    final payload = <String, dynamic>{
      'name': name,
      'type': _selectedType,
      'icon': _selectedIconKey,
      'color': colorHex,
    };
    if (_selectedParentCategoryId != null && _selectedParentCategoryId!.isNotEmpty) {
      payload['parentCategoryId'] = _selectedParentCategoryId;
    }

    final success = await ref.read(categoryProvider.notifier).addCategory(payload);

    setState(() => _isSaving = false);

    if (success && mounted) {
      final updatedCategories = ref.read(categoryProvider).categories;
      final created = updatedCategories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
        orElse: () => updatedCategories.isNotEmpty ? updatedCategories.last : updatedCategories.first,
      );
      if (widget.onCategoryCreated != null) {
        widget.onCategoryCreated!(created.id);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Category',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type Selector (Expense vs Income)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == 'expense'
                              ? AppColors.expenseRose.withOpacity(0.2)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedType == 'expense'
                                ? AppColors.expenseRose
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          'Expense',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == 'expense'
                                ? AppColors.expenseRose
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == 'income'
                              ? AppColors.incomeEmerald.withOpacity(0.2)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedType == 'income'
                                ? AppColors.incomeEmerald
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          'Income',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == 'income'
                                ? AppColors.incomeEmerald
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Parent Category Selector (Optional for Subcategories)
              Text(
                'Parent Category (Optional - For Subcategories)',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedParentCategoryId,
                    hint: Text('None (Primary Parent Category)', style: GoogleFonts.outfit(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    dropdownColor: AppColors.surfaceContainerHigh,
                    isExpanded: true,
                    style: GoogleFonts.outfit(color: AppColors.onSurface),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Primary Parent Category)', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      ...ref.watch(categoryProvider).categories
                          .where((c) => c.parentCategoryId == null && c.type == _selectedType)
                          .map((parentCat) {
                        return DropdownMenuItem<String?>(
                          value: parentCat.id,
                          child: Text(parentCat.name, style: GoogleFonts.outfit(color: AppColors.onSurface)),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedParentCategoryId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Name Input
              Text(
                'Category Name',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: GoogleFonts.outfit(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'e.g. Groceries, Gym, Investment',
                  hintStyle: GoogleFonts.outfit(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Icon Picker Grid
              Text(
                'Select Icon',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: CategoryIcons.availableIcons.length,
                  itemBuilder: (context, index) {
                    final item = CategoryIcons.availableIcons[index];
                    final isSelected = item.key == _selectedIconKey;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconKey = item.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withOpacity(0.3) : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _selectedColor : AppColors.glassBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: isSelected ? _selectedColor : AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Color Palette Picker
              Text(
                'Select Badge Color',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: CategoryIcons.availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Create Category',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
