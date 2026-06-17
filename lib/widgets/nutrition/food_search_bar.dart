// lib/widgets/nutrition/food_search_bar.dart
// Search bar with category filtering chips

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'meal_helpers.dart';

class FoodSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<String> categories;

  const FoodSearchBar({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.categories = const ['الكل', 'كارب', 'بروتين', 'خضار', 'فاكهة', 'دهون'],
  });

  @override
  State<FoodSearchBar> createState() => _FoodSearchBarState();
}

class _FoodSearchBarState extends State<FoodSearchBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.nutrition.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search, color: AppColors.nutrition, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'إضافة طعام',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search field
        TextField(
          controller: widget.searchController,
          decoration: InputDecoration(
            hintText: 'ابحث عن طعام...',
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            suffixIcon: widget.searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      widget.searchController.clear();
                      widget.onCategoryChanged(widget.selectedCategory);
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),

        // Categories
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: widget.categories.map((cat) {
              final isSelected = widget.selectedCategory == cat;
              final color = cat == 'الكل'
                  ? AppColors.primary
                  : getCategoryColor(cat);
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat != 'الكل') ...[
                        Text(getCategoryEmoji(cat), style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                      ],
                      Text(cat),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => widget.onCategoryChanged(cat),
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isSelected ? color : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}