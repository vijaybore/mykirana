import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'localization/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_verify_screen.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/udhari/screens/udhari_customer_list_screen.dart';
import 'features/udhari/screens/my_udhari_screen.dart';

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
        // Udhari core (Step 3) is now the owner/customer entry point.
        // TODO: swap these for the real Owner Dashboard (Step 10) and
        // Customer Browse Home (Step 7) once those are built — udhari
        // remains reachable from within both as a nav destination.
        '/owner/dashboard': (context) => const UdhariCustomerListScreen(),
        '/customer/home': (context) => const MyUdhariScreen(),
      },
    );
  }
}

