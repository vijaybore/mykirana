import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/screen_util.dart';
import 'localization/app_localizations.dart';
import 'providers/auth_provider.dart' show UserRole;
import 'providers/locale_provider.dart';
import 'providers/session_provider.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/welcome_role_screen.dart';
import 'features/auth/screens/otp_verify_screen.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/shop/screens/shop_setup_screen.dart';
import 'features/shop/screens/shop_link_screen.dart';
import 'features/shop/screens/owner_dashboard_screen.dart';
import 'features/shop/screens/customer_home_screen.dart';
import 'features/shop/screens/shop_qr_screen.dart';
import 'features/shop/screens/shop_edit_screen.dart';
import 'features/products/screens/owner_product_list_screen.dart';
import 'features/products/screens/customer_browse_screen.dart';
import 'features/cart/screens/cart_screen.dart';
import 'features/orders/screens/owner_orders_screen.dart';
import 'features/orders/screens/customer_orders_screen.dart';

/// Figures out where a returning user should land, based on what was
/// persisted locally at the last app close (see main.dart's bootstrap
/// step). This is the "always there" behavior from the plan: once a
/// shop is created or linked, the app skips straight back to it
/// instead of re-running auth/setup every time.
String _resolveInitialRoute(SessionState session) {
  if (session.role == null) {
    return '/'; // never started — ask role
  }
  
  if (session.role == UserRole.owner && session.userId == null) {
    return '/auth/phone'; // Owner chose role but hasn't logged in yet
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
        // Initialise responsive scale factors from the real MediaQuery.
        // This must happen inside builder so MediaQuery is available.
        ScreenUtil.init(MediaQuery.of(context));
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
        '/': (context) => const WelcomeRoleScreen(),
        '/auth/phone': (context) => const PhoneInputScreen(),
        '/auth/otp': (context) => const OtpVerifyScreen(),
        '/auth/role': (context) => const RoleSelectScreen(),
        '/owner/shop-setup': (context) => const ShopSetupScreen(),
        '/customer/shop-link': (context) => const ShopLinkScreen(),
        '/owner/dashboard': (context) => const OwnerDashboardScreen(),
        '/owner/products': (context) => const OwnerProductListScreen(),
        '/owner/orders': (context) => const OwnerOrdersScreen(),
        '/owner/shop-qr': (context) => const ShopQrScreen(),
        '/owner/shop-edit': (context) => const ShopEditScreen(),
        '/customer/home': (context) => const CustomerHomeScreen(),
        '/customer/browse': (context) => const CustomerBrowseScreen(),
        '/customer/cart': (context) => const CartScreen(),
        '/customer/orders': (context) => const CustomerOrdersScreen(),
      },
    );
  }
}