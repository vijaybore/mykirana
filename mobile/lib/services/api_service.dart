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
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

