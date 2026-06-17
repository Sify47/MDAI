import 'package:flutter/material.dart';

class WaterTipsCard extends StatelessWidget {
  const WaterTipsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '💡 نصائح لشرب الماء',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('🥤', 'اشرب كوب ماء قبل كل وجبة', theme),
          _buildTipItem('📱', 'استخدم تطبيق تذكير كل ساعة', theme),
          _buildTipItem('🍋', 'أضف شرائح ليمون أو نعناع لتحسين الطعم', theme),
          _buildTipItem('🏃', 'اشرب ماء قبل وبعد التمرين', theme),
        ],
      ),
    );
  }

  Widget _buildTipItem(String icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
