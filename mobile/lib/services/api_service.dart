import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper around the MyKirana backend REST API.
/// Base URL is swappable per environment — point it at your local
/// backend during development, then at the deployed Render/Railway
/// URL for staging/production builds.
class ApiService {
  ApiService({this.baseUrl = 'http://10.0.2.2:4000'});

  /// 10.0.2.2 is the Android emulator's alias for the host machine's
  /// localhost. Use your machine's LAN IP instead when testing on a
  /// real device, or the deployed backend URL for staging/production.
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<Map<String, dynamic>>> getUdhariCustomers(String shopId) async {
    final res = await http.get(_uri('/udhari/customers/$shopId'));
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getUdhariHistory(
    String shopId,
    String customerId,
  ) async {
    final res = await http.get(_uri('/udhari/history/$shopId/$customerId'));
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<double> getUdhariBalance(String shopId, String customerId) async {
    final res = await http.get(_uri('/udhari/balance/$shopId/$customerId'));
    _throwIfError(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return double.parse(body['balance'].toString());
  }

  Future<Map<String, dynamic>> addUdhariEntry({
    required String shopId,
    required String customerId,
    required String type, // 'credit' | 'payment'
    required double amount,
    String? note,
  }) async {
    final res = await http.post(
      _uri('/udhari'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'shopId': shopId,
        'customerId': customerId,
        'type': type,
        'amount': amount,
        'note': note,
      }),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
  }

  // ── Users ──────────────────────────────────────────────────────

  /// Creates the user on first login, or returns the existing record
  /// if this phone number already has one (backend upserts by phone).
  Future<Map<String, dynamic>> upsertUser({
    required String phone,
    required String role,
    String? name,
    String language = 'mr',
  }) async {
    final res = await http.post(
      _uri('/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'role': role,
        'name': name,
        'language': language,
      }),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Shops ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createShop({
    required String ownerId,
    required String shopName,
    String? address,
    String? businessUpiId,
  }) async {
    final res = await http.post(
      _uri('/shops'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ownerId': ownerId,
        'shopName': shopName,
        'address': address,
        'businessUpiId': businessUpiId,
      }),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Returns null (rather than throwing) on a 404, since "shop not
  /// found for this code" is an expected, common outcome the shop-
  /// linking screen needs to show inline, not treat as a crash.
  Future<Map<String, dynamic>?> getShopByCode(String code) async {
    final res = await http.get(_uri('/shops/by-code/$code'));
    if (res.statusCode == 404) return null;
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getShopByOwner(String ownerId) async {
    final res = await http.get(_uri('/shops/by-owner/$ownerId'));
    if (res.statusCode == 404) return null;
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Customer ↔ Shop links ─────────────────────────────────────

  Future<Map<String, dynamic>> linkCustomerToShop({
    required String customerId,
    required String shopId,
  }) async {
    final res = await http.post(
      _uri('/customer-shop-links'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId, 'shopId': shopId}),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// A customer can only be linked to one shop in this pilot, so this
  /// returns their single linked shop (or null) — used at app
  /// bootstrap to skip straight past the shop-link screen next time.
  Future<Map<String, dynamic>?> getLinkedShopForCustomer(
    String customerId,
  ) async {
    final res = await http.get(_uri('/customer-shop-links/$customerId'));
    if (res.statusCode == 404) return null;
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

