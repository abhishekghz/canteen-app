import 'package:flutter/material.dart';

/// Admin contact shown across the app for issues/errors.
const kAdminName = 'Abhishek Gautam';
const kAdminEmail = 'gautam.abhishek7100@gmail.com';

/// A compact, selectable "contact admin" footer.
class ContactAdminFooter extends StatelessWidget {
  const ContactAdminFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      children: [
        Text('Facing an issue or error? Contact the admin:',
            textAlign: TextAlign.center, style: style),
        const SizedBox(height: 2),
        SelectableText(
          '$kAdminName · $kAdminEmail',
          textAlign: TextAlign.center,
          style: style?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Shows the admin contact in a dialog (used from in-app menus).
Future<void> showContactAdminDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      icon: const Icon(Icons.support_agent),
      title: const Text('Need help?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('For any issue or error, contact the admin:',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(kAdminName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SelectableText(kAdminEmail),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
