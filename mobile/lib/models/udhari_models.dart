enum UdhariType { credit, payment }

extension UdhariTypeX on UdhariType {
  String get apiValue => this == UdhariType.credit ? 'credit' : 'payment';

  static UdhariType fromApi(String value) =>
      value == 'credit' ? UdhariType.credit : UdhariType.payment;
}

/// One entry in a customer's udhari history — either goods taken on
/// credit, or a payment received against the balance.
class UdhariTransaction {
  final String id;
  final String shopId;
  final String customerId;
  final UdhariType type;
  final double amount;
  final String? note;
  final DateTime createdAt;

  UdhariTransaction({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.type,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  factory UdhariTransaction.fromJson(Map<String, dynamic> json) {
    return UdhariTransaction(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      customerId: json['customer_id'] as String,
      type: UdhariTypeX.fromApi(json['type'] as String),
      amount: double.parse(json['amount'].toString()),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// A row in the owner's udhari customer list — name, phone, and
/// running balance, as returned by GET /udhari/customers/:shopId
class UdhariCustomerSummary {
  final String customerId;
  final String? name;
  final String phone;
  final double balance;

  UdhariCustomerSummary({
    required this.customerId,
    this.name,
    required this.phone,
    required this.balance,
  });

  factory UdhariCustomerSummary.fromJson(Map<String, dynamic> json) {
    return UdhariCustomerSummary(
      customerId: json['customer_id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String,
      balance: double.parse(json['balance'].toString()),
    );
  }

  String get displayName => (name != null && name!.trim().isNotEmpty)
      ? name!
      : phone;
}

