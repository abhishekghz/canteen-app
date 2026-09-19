import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_day.dart';
import '../../providers.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekProvider);
    return weekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load menu: $e')),
      data: (week) {
        final ordered = [...week]..sort((a, b) =>
            kWeekdays.indexOf(a.weekday) - kWeekdays.indexOf(b.weekday));
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final day in ordered) _DayCard(day: day),
          ],
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final MenuDay day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(weekdayLabel(day.weekday),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _meal(context, 'Breakfast', day.breakfast),
            _meal(context, 'Lunch', day.lunch),
            _meal(context, 'Dinner', day.dinner),
          ],
        ),
      ),
    );
  }

  Widget _meal(BuildContext context, String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(items.isEmpty ? '—' : items.join(', ')),
          ),
        ],
      ),
    );
  }
}
