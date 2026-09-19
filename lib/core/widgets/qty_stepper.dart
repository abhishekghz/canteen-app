import 'package:flutter/material.dart';

/// A compact +/- quantity control.
class QtyStepper extends StatelessWidget {
  final String label;
  final String? subtitle;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  const QtyStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.min = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 36,
          child: Text('$value', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton.outlined(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
