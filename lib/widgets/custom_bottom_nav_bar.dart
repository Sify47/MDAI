import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignConstants.radiusFeatured),
          topRight: Radius.circular(DesignConstants.radiusFeatured),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_filled,
                label: 'الرئيسية',
                isSelected: widget.currentIndex == 0,
                theme: theme,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.grid_view_rounded,
                label: 'الخدمات',
                isSelected: widget.currentIndex == 1,
                theme: theme,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'البروفايل',
                isSelected: widget.currentIndex == 2,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.5);
    final backgroundColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.12)
        : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _animationController.forward(from: 0);
          widget.onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: DesignConstants.borderRadiusCard,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  double scale = 1.0;
                  double translateY = 0.0;

                  if (isSelected && _animationController.isAnimating) {
                    scale = 1 + (0.2 * (1 - _animationController.value));
                    translateY = -4 * (1 - _animationController.value);
                  }

                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
