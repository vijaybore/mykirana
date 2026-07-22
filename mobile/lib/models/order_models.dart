import 'product_models.dart';

/// One line in the customer's cart — a product plus the quantity chosen.
/// This is what gets snapshotted into an order's `items` when placed.
class CartLine {
  final Product product;
  final int quantity;

  CartLine({required this.product, required this.quantity});

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);

  double get lineTotal => product.price * quantity;

  Map<String, dynamic> toOrderItem() => {
        'product_id': product.id,
        'name': product.name,
        'price': product.price,
        'quantity': quantity,
      };
}

enum PaymentMode { cash, upi, udhari }

extension PaymentModeX on PaymentMode {
  String get apiValue {
    switch (this) {
      case PaymentMode.cash:
        return 'cash';
      case PaymentMode.upi:
        return 'upi';
      case PaymentMode.udhari:
        return 'udhari';
    }
  }

  static PaymentMode fromApi(String value) {
    switch (value) {
      case 'upi':
        return PaymentMode.upi;
      case 'udhari':
        return PaymentMode.udhari;
      default:
        return PaymentMode.cash;
    }
  }
}

enum FulfillmentType { pickup, delivery }

extension FulfillmentTypeX on FulfillmentType {
  String get apiValue => this == FulfillmentType.delivery ? 'delivery' : 'pickup';

  static FulfillmentType fromApi(String? value) {
    return value == 'delivery' ? FulfillmentType.delivery : FulfillmentType.pickup;
  }
}

enum OrderStatus { placed, ready, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get apiValue {
    switch (this) {
      case OrderStatus.placed:
        return 'placed';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Position in the pickup flow — drives the order-status stepper UI.
  /// Only meaningful for placed/ready/completed; cancelled is a
  /// terminal side-state the stepper renders separately rather than
  /// treating as "step 4" of the same progression.
  int get stepIndex => index;

  static OrderStatus fromApi(String value) {
    switch (value) {
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.placed;
    }
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      price: double.parse((json['price'] ?? 0).toString()),
      quantity: int.parse((json['quantity'] ?? 0).toString()),
    );
  }

  double get lineTotal => price * quantity;
}

class Order {
  final String id;
  final String shopId;
  final String customerId;
  final List<OrderItem> items;
  final PaymentMode paymentMode;
  final String paymentStatus; // 'pending' | 'confirmed'
  final FulfillmentType fulfillmentType;
  final OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.items,
    required this.paymentMode,
    required this.paymentStatus,
    required this.fulfillmentType,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = (rawItems is List ? rawItems : <dynamic>[])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      customerId: json['customer_id'] as String,
      items: itemsList,
      paymentMode: PaymentModeX.fromApi(json['payment_mode'] as String),
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      fulfillmentType: FulfillmentTypeX.fromApi(json['fulfillment_type'] as String?),
      status: OrderStatusX.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  double get total => items.fold(0, (sum, i) => sum + i.lineTotal);

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}
