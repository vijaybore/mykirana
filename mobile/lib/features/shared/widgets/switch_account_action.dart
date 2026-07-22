import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';

/// An AppBar action that signs the current user out and returns to the
/// very start of the app. Session.signOut() already existed and
/// correctly clears both in-memory state and local persistence — it
/// just had no button anywhere calling it, so a role/shop was
/// permanently "stuck" once picked.
class SwitchAccountAction extends ConsumerWidget {
  const SwitchAccountAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: t.t('accountSwitchAction'),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(t.t('accountSwitchConfirmTitle')),
            content: Text(t.t('accountSwitchConfirmBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(t.t('commonCancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(t.t('accountSwitchAction')),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          ref.read(sessionProvider.notifier).signOut();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      },
    );
  }
}
