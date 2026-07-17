import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'localization/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_verify_screen.dart';
import 'features/auth/screens/role_select_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'MyKirana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      builder: (context, child) {
        return Container(
          color: const Color(0xFFE5E7E3),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                color: AppTheme.light.scaffoldBackgroundColor,
                child: child,
              ),
            ),
          ),
        );
      },
      routes: {
        '/': (context) => const PhoneInputScreen(),
        '/auth/otp': (context) => const OtpVerifyScreen(),
        '/auth/role': (context) => const RoleSelectScreen(),
        '/owner/dashboard': (context) => const _PlaceholderHome(
              label: 'Owner Dashboard — coming in Step 10',
            ),
        '/customer/home': (context) => const _PlaceholderHome(
              label: 'Customer Browse Home — coming in Step 7',
            ),
      },
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}

