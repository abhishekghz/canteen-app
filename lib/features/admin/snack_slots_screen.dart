import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/snack_slot.dart';
import '../../providers.dart';

class SnackSlotsScreen extends ConsumerWidget {
  const SnackSlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(snackSlotsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Snack Slots')),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (slots) => _SlotsEditor(slots: slots),
      ),
    );
  }
}

class _SlotsEditor extends ConsumerStatefulWidget {
  final List<SnackSlot> slots;
  const _SlotsEditor({required this.slots});
  @override
  ConsumerState<_SlotsEditor> createState() => _SlotsEditorState();
}

class _SlotsEditorState extends ConsumerState<_SlotsEditor> {
  late List<SnackSlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = [...widget.slots];
  }

  Future<void> _save() async {
    await ref.read(snackRepositoryProvider).saveSlots(_slots);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Snack slots saved')));
    }
  }

  void _addSlot() {
    setState(() {
      _slots = [
        ..._slots,
        SnackSlot(
          id: 'slot${DateTime.now().millisecondsSinceEpoch}',
          label: 'New Slot',
          time: '12:00',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < _slots.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: _slots[i].label,
                      decoration: const InputDecoration(labelText: 'Label'),
                      onChanged: (v) =>
                          _slots[i] = _slots[i].copyWith(label: v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: _slots[i].time,
                      decoration:
                          const InputDecoration(labelText: 'Time (HH:mm)'),
                      onChanged: (v) => _slots[i] = _slots[i].copyWith(time: v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _slots.removeAt(i)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addSlot,
          icon: const Icon(Icons.add),
          label: const Text('Add slot'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Save slots'),
        ),
      ],
    );
  }
}
