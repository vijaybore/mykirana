import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'localization/app_localizations.dart';
import 'providers/auth_provider.dart' show UserRole;
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_verify_screen.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/shop/screens/shop_setup_screen.dart';
import 'features/shop/screens/shop_link_screen.dart';
import 'features/udhari/screens/udhari_customer_list_screen.dart';
import 'features/udhari/screens/my_udhari_screen.dart';

/// Figures out where a returning user should land, based on what was
/// persisted locally at the last app close (see main.dart's bootstrap
/// step). This is the "always there" behavior from the plan: once a
/// shop is created or linked, the app skips straight back to it
/// instead of re-running auth/setup every time.
String _resolveInitialRoute(SessionState session) {
  if (session.userId == null || session.role == null) {
    return '/'; // never completed login — start fresh
  }
  if (session.hasLinkedShop) {
    return session.role == UserRole.owner
        ? '/owner/dashboard'
        : '/customer/home';
  }
  // Logged in, but hasn't finished shop setup/linking yet.
  return session.role == UserRole.owner
      ? '/owner/shop-setup'
      : '/customer/shop-link';
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    // Read (not watch) — initialRoute is only consulted once by the
    // Navigator on first build, so this doesn't need to react to
    // later session changes; screens navigate explicitly instead.
    final session = ref.read(sessionProvider);

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
      initialRoute: _resolveInitialRoute(session),
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
        '/owner/shop-setup': (context) => const ShopSetupScreen(),
        '/customer/shop-link': (context) => const ShopLinkScreen(),
        // Udhari core (Step 3) is the owner/customer home for now.
        // TODO: swap these for the real Owner Dashboard (Step 10) and
        // Customer Browse Home (Step 7) once those are built — udhari
        // remains reachable from within both as a nav destination.
        '/owner/dashboard': (context) => const UdhariCustomerListScreen(),
        '/customer/home': (context) => const MyUdhariScreen(),
      },
    );
  }
}