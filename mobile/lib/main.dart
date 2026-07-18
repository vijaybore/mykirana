import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/auth_provider.dart' show UserRoleX;
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';
import 'services/local_prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load whatever was persisted last time (language, role, linked
  // shop) *before* the first frame, so the app opens straight into
  // the right language and — for a returning owner/customer — the
  // right screen, instead of flashing English/login first.
  final prefs = LocalPrefsService();
  final bootstrap = await prefs.loadBootstrapState();

  final initialLocale = Locale(bootstrap.localeCode ?? 'mr');
  final initialSession = SessionState(
    userId: bootstrap.userId,
    role: UserRoleX.fromApi(bootstrap.role),
    shopId: bootstrap.shopId,
    shopName: bootstrap.shopName,
    shopCode: bootstrap.shopCode,
  );

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(
          (ref) => LocaleNotifier(prefs, initialLocale),
        ),
        sessionProvider.overrideWith(
          (ref) => SessionNotifier(prefs, initialSession),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

