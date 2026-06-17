import 'package:flutter/material.dart';

class WaterTodayIntakes extends StatelessWidget {
  final List<Map<String, dynamic>> intakes;
  final Future<void> Function(int id) onDeleteIntake;

  const WaterTodayIntakes({
    Key? key,
    required this.intakes,
    required this.onDeleteIntake,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (intakes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.water_drop_outlined, size: 48),
              SizedBox(height: 8),
              Text('لم تسجل أي كمية ماء اليوم'),
              SizedBox(height: 4),
              Text('اضغط على الزر أعلاه لتسجيل'),
            ],
          ),
        ),
      );
    }

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
            'سجل اليوم',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: intakes.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final intake = intakes[index];
              final time = DateTime.parse(intake['time']);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.water_drop, color: Colors.blue),
                ),
                title: Text('${intake['amount']} لتر'),
                subtitle: Text(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => onDeleteIntake(intake['id']),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
