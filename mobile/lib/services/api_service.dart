import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Picks a sensible default backend URL per platform, so switching
/// between "flutter run -d chrome" and an Android emulator doesn't
/// require hand-editing this file (which is exactly how this default
/// kept quietly reverting during development).
///
/// - Web (Chrome): the backend is just a normal process on your own
///   machine, reachable at plain localhost.
/// - Android emulator: 10.0.2.2 is the emulator's special alias for
///   the host machine's localhost — "localhost" from inside the
///   emulator means the emulator itself, not your PC.
/// - Real device / staging / production: neither default is reachable
///   (a phone can't resolve "localhost" to your laptop) — pass an
///   explicit baseUrl (your LAN IP, or the deployed backend URL) when
///   constructing ApiService in that case.
String _defaultBaseUrl() {
  if (kIsWeb) return 'http://localhost:4000';
  return 'http://10.0.2.2:4000';
}

/// Thin wrapper around the MyKirana backend REST API.
/// Base URL is swappable per environment — point it at your local
/// backend during development, then at the deployed Render/Railway
/// URL for staging/production builds.
class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  final String baseUrl;

  /// Every request gets a hard timeout. Without this, a request to an
  /// unreachable host (backend not running, wrong IP, no network) just
  /// hangs — no error, no timeout — which is what makes a "Next" button
  /// spin forever with no way for the UI to ever show a retry state.
  static const _timeout = Duration(seconds: 12);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json',
      };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        0,
        'Could not reach the server at $baseUrl. Check that the backend '
        'is running and reachable from this device.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Network error: $e');
    }
  }

  Future<http.Response> _get(String path) =>
      _send(() => http.get(_uri(path)));

  Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      _send(() => http.post(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)));

  Future<http.Response> _put(String path, Map<String, dynamic> body) =>
      _send(() => http.put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)));

  Future<http.Response> _patch(String path, Map<String, dynamic> body) =>
      _send(() => http.patch(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)));

  Future<http.Response> _delete(String path) =>
      _send(() => http.delete(_uri(path)));

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
  }

  // ── Udhari ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUdhariCustomers(String shopId) async {
    final res = await _get('/udhari/customers/$shopId');
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getUdhariHistory(
    String shopId,
    String customerId,
  ) async {
    final res = await _get('/udhari/history/$shopId/$customerId');
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<double> getUdhariBalance(String shopId, String customerId) async {
    final res = await _get('/udhari/balance/$shopId/$customerId');
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
    final res = await _post('/udhari', {
      'shopId': shopId,
      'customerId': customerId,
      'type': type,
      'amount': amount,
      'note': note,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
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
    final res = await _post('/users', {
      'phone': phone,
      'role': role,
      'name': name,
      'language': language,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Shops ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createShop({
    required String ownerId,
    required String shopName,
    String? address,
    String? businessUpiId,
    String? contactPhone,
    String? shopImageUrl,
    String? upiQrImageUrl,
  }) async {
    final res = await _post('/shops', {
      'ownerId': ownerId,
      'shopName': shopName,
      'address': address,
      'businessUpiId': businessUpiId,
      'contactPhone': contactPhone,
      'shopImageUrl': shopImageUrl,
      'upiQrImageUrl': upiQrImageUrl,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateShop({
    required String id,
    String? shopName,
    String? address,
    String? businessUpiId,
    String? contactPhone,
    String? shopImageUrl,
    String? upiQrImageUrl,
  }) async {
    final res = await _put('/shops/$id', {
      'shopName': shopName,
      'address': address,
      'businessUpiId': businessUpiId,
      'contactPhone': contactPhone,
      'shopImageUrl': shopImageUrl,
      'upiQrImageUrl': upiQrImageUrl,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Returns null (rather than throwing) on a 404, since "shop not
  /// found for this code" is an expected, common outcome the shop-
  /// linking screen needs to show inline, not treat as a crash.
  Future<Map<String, dynamic>?> getShopByCode(String code) async {
    final res = await _get('/shops/by-code/$code');
    if (res.statusCode == 404) return null;
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getShopByOwner(String ownerId) async {
    final res = await _get('/shops/by-owner/$ownerId');
    if (res.statusCode == 404) return null;
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Customer ↔ Shop links ─────────────────────────────────────

  Future<Map<String, dynamic>> linkCustomerToShop({
    required String customerId,
    required String shopId,
  }) async {
    final res = await _post('/customer-shop-links', {
      'customerId': customerId,
      'shopId': shopId,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// A customer can only be linked to one shop in this pilot, so this
  /// returns their single linked shop (or null) — used at app
  /// bootstrap to skip straight past the shop-link screen next time.
  Future<Map<String, dynamic>?> getLinkedShopForCustomer(
    String customerId,
  ) async {
    final res = await _get('/customer-shop-links/$customerId');
    if (res.statusCode == 404) return null;
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Categories ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories(String shopId) async {
    final res = await _get('/categories/$shopId');
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCategory({
    required String shopId,
    required String name,
  }) async {
    final res = await _post('/categories', {'shopId': shopId, 'name': name});
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteCategory(String id) async {
    final res = await _delete('/categories/$id');
    _throwIfError(res);
  }

  // ── Products ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProducts(
    String shopId, {
    String? categoryId,
    String? search,
    bool inStockOnly = false,
  }) async {
    final params = <String, String>{};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (inStockOnly) params['inStockOnly'] = 'true';

    final uri = Uri.parse('$baseUrl/products/$shopId')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await _send(() => http.get(uri));
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProduct({
    required String shopId,
    String? categoryId,
    required String name,
    required double price,
    required String unit,
    String? imageUrl,
    bool inStock = true,
  }) async {
    final res = await _post('/products', {
      'shopId': shopId,
      'categoryId': categoryId,
      'name': name,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
      'inStock': inStock,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    String? categoryId,
    String? name,
    double? price,
    String? unit,
    String? imageUrl,
  }) async {
    final res = await _put('/products/$id', {
      'categoryId': categoryId,
      'name': name,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setProductStock({
    required String id,
    required bool inStock,
  }) async {
    final res = await _patch('/products/$id/stock', {'inStock': inStock});
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteProduct(String id) async {
    final res = await _delete('/products/$id');
    _throwIfError(res);
  }

  // ── Orders ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> placeOrder({
    required String shopId,
    required String customerId,
    required List<Map<String, dynamic>> items,
    required String paymentMode, // 'cash' | 'upi' | 'udhari'
    String fulfillmentType = 'pickup',
  }) async {
    final res = await _post('/orders', {
      'shopId': shopId,
      'customerId': customerId,
      'items': items,
      'paymentMode': paymentMode,
      'fulfillmentType': fulfillmentType,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getShopOrders(
    String shopId, {
    String? status,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$baseUrl/orders/shop/$shopId')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await _send(() => http.get(uri));
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId, {
    String? shopId,
  }) async {
    final params = <String, String>{};
    if (shopId != null) params['shopId'] = shopId;
    final uri = Uri.parse('$baseUrl/orders/customer/$customerId')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await _send(() => http.get(uri));
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String id,
    required String status, // 'placed' | 'ready' | 'completed'
  }) async {
    final res = await _patch('/orders/$id/status', {'status': status});
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOrderPaymentStatus({
    required String id,
    required String paymentStatus, // 'pending' | 'confirmed'
  }) async {
    final res = await _patch('/orders/$id/payment-status', {
      'paymentStatus': paymentStatus,
    });
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  /// True when this failure never reached the server at all (timeout,
  /// DNS failure, connection refused) — distinct from the server
  /// responding with a 4xx/5xx. Screens use this to show "can't reach
  /// the server" instead of a generic error.
  bool get isConnectionError => statusCode == 0;

  /// Attempts to parse the response body as JSON and return the 'error' field.
  /// Falls back to the raw body string if parsing fails.
  String get message {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json.containsKey('error')) {
        return json['error'] as String;
      }
    } catch (_) {}
    return body;
  }

  @override
  String toString() => 'ApiException($statusCode): $body';
}
