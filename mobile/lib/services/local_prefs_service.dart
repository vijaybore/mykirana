import 'package:shared_preferences/shared_preferences.dart';

class BootstrapState {
  final String? localeCode;
  final String? userId;
  final String? role;
  final String? shopId;
  final String? shopName;
  final String? shopCode;

  const BootstrapState({
    this.localeCode,
    this.userId,
    this.role,
    this.shopId,
    this.shopName,
    this.shopCode,
  });
}

class LocalPrefsService {
  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<BootstrapState> loadBootstrapState() async {
    final prefs = await _prefs;

    return BootstrapState(
      localeCode: prefs.getString('locale_code'),
      userId: prefs.getString('user_id'),
      role: prefs.getString('role'),
      shopId: prefs.getString('shop_id'),
      shopName: prefs.getString('shop_name'),
      shopCode: prefs.getString('shop_code'),
    );
  }

  Future<void> saveLocale(String localeCode) async {
    final prefs = await _prefs;
    await prefs.setString('locale_code', localeCode);
  }

  Future<void> saveRole(String role) async {
    final prefs = await _prefs;
    await prefs.setString('role', role);
  }

  Future<void> saveUser({
    required String userId,
    required String role,
  }) async {
    final prefs = await _prefs;

    await prefs.setString('user_id', userId);
    await prefs.setString('role', role);
  }

  Future<void> saveLinkedShop({
    required String shopId,
    required String shopName,
    required String shopCode,
  }) async {
    final prefs = await _prefs;

    await prefs.setString('shop_id', shopId);
    await prefs.setString('shop_name', shopName);
    await prefs.setString('shop_code', shopCode);
  }

  Future<void> clearLinkedShop() async {
    final prefs = await _prefs;

    await prefs.remove('shop_id');
    await prefs.remove('shop_name');
    await prefs.remove('shop_code');
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}