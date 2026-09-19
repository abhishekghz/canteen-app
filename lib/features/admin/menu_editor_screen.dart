import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_day.dart';
import '../../providers.dart';

class MenuEditorScreen extends ConsumerWidget {
  const MenuEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Menu')),
      body: weekAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (week) {
          final ordered = [...week]..sort((a, b) =>
              kWeekdays.indexOf(a.weekday) - kWeekdays.indexOf(b.weekday));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [for (final d in ordered) _DayEditor(day: d)],
          );
        },
      ),
    );
  }
}

class _DayEditor extends ConsumerStatefulWidget {
  final MenuDay day;
  const _DayEditor({required this.day});
  @override
  ConsumerState<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends ConsumerState<_DayEditor> {
  late final TextEditingController _b;
  late final TextEditingController _l;
  late final TextEditingController _d;

  @override
  void initState() {
    super.initState();
    _b = TextEditingController(text: widget.day.breakfast.join('\n'));
    _l = TextEditingController(text: widget.day.lunch.join('\n'));
    _d = TextEditingController(text: widget.day.dinner.join('\n'));
  }

  @override
  void dispose() {
    _b.dispose();
    _l.dispose();
    _d.dispose();
    super.dispose();
  }

  List<String> _parse(String text) => text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final updated = widget.day.copyWith(
      breakfast: _parse(_b.text),
      lunch: _parse(_l.text),
      dinner: _parse(_d.text),
    );
    await ref.read(menuRepositoryProvider).saveDay(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${weekdayLabel(widget.day.weekday)} saved')),
      );
    }
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          maxLines: null,
          decoration: InputDecoration(
            labelText: '$label (one item per line)',
            alignLabelWithHint: true,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text(weekdayLabel(widget.day.weekday)),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          _field(_b, 'Breakfast'),
          _field(_l, 'Lunch'),
          _field(_d, 'Dinner'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save day'),
          ),
        ],
      ),
    );
  }
}
