import 'package:flutter/material.dart';

class WaterQuickAddCard extends StatelessWidget {
  final double cupSize;
  final void Function(double amount) onLogWater;
  final VoidCallback onShowCustomDialog;

  const WaterQuickAddCard({
    Key? key,
    required this.cupSize,
    required this.onLogWater,
    required this.onShowCustomDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تسجيل سريع',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickAddButton(theme, cupSize, 'كوب'),
              const SizedBox(width: 12),
              _buildQuickAddButton(theme, 0.5, 'لتر'),
              const SizedBox(width: 12),
              _buildQuickAddButton(theme, 1.0, 'لتر'),
              const SizedBox(width: 12),
              _buildCustomAddButton(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(ThemeData theme, double amount, String label) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => onLogWater(amount),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '+ $amount $label',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCustomAddButton(ThemeData theme) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onShowCustomDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text('مخصص'),
      ),
    );
  }
}
