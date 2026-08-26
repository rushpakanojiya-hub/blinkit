import '../services/api_service.dart';

enum OrderStatus { active, delivered, cancelled }

String _imageHost() => ApiService.baseUrl.replaceAll('/api/v1', '');

String _resolveImage(String? raw) {
  final url = (raw ?? '').toString();
  if (url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${_imageHost()}$url';
}

class OrderItem {
  final int id;
  final int? productId;
  final String name;
  final String image;
  final String unit;
  final int quantity;
  final int price;

  OrderItem({
    required this.id,
    this.productId,
    required this.name,
    required this.image,
    required this.unit,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final rawProductId = product['id'];
    return OrderItem(
      id: (json['id'] ?? 0) is int ? json['id'] as int : (json['id'] as num).toInt(),
      productId: rawProductId is int
          ? rawProductId
          : (rawProductId is num ? rawProductId.toInt() : int.tryParse(rawProductId?.toString() ?? '')),
      name: (product['name'] ?? 'Item').toString(),
      image: _resolveImage(product['image_url']?.toString()),
      unit: '1 unit',
      quantity: (json['quantity'] ?? 1) is int
          ? json['quantity'] as int
          : (json['quantity'] as num).toInt(),
      price: (json['price'] is num) ? (json['price'] as num).round() : 0,
    );
  }
}

class OrderTimelineStep {
  final String title;
  final String? time;
  final bool completed;
  OrderTimelineStep({required this.title, this.time, required this.completed});
}

class Order {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final OrderStatus status;
  final String rawStatus;
  final String address;
  final String paymentMethod;
  final String paymentStatus;
  final int itemTotal;
  final int deliveryFee;
  final int platformFee;
  final int discount;
  final List<OrderTimelineStep> timeline;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.status,
    required this.rawStatus,
    required this.address,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemTotal,
    required this.deliveryFee,
    required this.platformFee,
    this.discount = 0,
    required this.timeline,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get grandTotal => itemTotal + deliveryFee + platformFee - discount;

  String get statusLabel {
    switch (rawStatus) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'returned':
        return 'Returned';
      case 'cancelled':
        return 'Cancelled';
      default:
        return rawStatus;
    }
  }

  static OrderStatus _mapStatus(String raw) {
    switch (raw) {
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'returned':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.active;
    }
  }

  static String _formatAddress(dynamic addr) {
    if (addr is! Map) return '';
    final parts = [
      addr['line1'],
      addr['line2'],
      addr['city'],
      addr['state'],
      addr['pincode'],
    ].where((p) => p != null && p.toString().trim().isNotEmpty).map((p) => p.toString());
    return parts.join(', ');
  }

  static List<OrderTimelineStep> _buildTimeline(String status) {
    final placed = OrderTimelineStep(title: 'Order placed', time: 'Placed', completed: true);
    switch (status) {
      case 'pending':
        return [
          placed,
          OrderTimelineStep(title: 'Confirmed', time: null, completed: false),
          OrderTimelineStep(title: 'Out for delivery', time: null, completed: false),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'confirmed':
        return [
          placed,
          OrderTimelineStep(title: 'Confirmed', time: 'Confirmed', completed: true),
          OrderTimelineStep(title: 'Out for delivery', time: null, completed: false),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'picking':
      case 'picked':
      case 'packing':
      case 'packed':
        return [
          placed,
          OrderTimelineStep(title: 'Confirmed', time: 'Confirmed', completed: true),
          OrderTimelineStep(title: 'Preparing your order', time: 'Preparing', completed: true),
          OrderTimelineStep(title: 'Out for delivery', time: null, completed: false),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'ready_for_dispatch':
      case 'handed_over':
      case 'shipped':
        return [
          placed,
          OrderTimelineStep(title: 'Confirmed', time: 'Confirmed', completed: true),
          OrderTimelineStep(title: 'Preparing your order', time: 'Preparing', completed: true),
          OrderTimelineStep(title: 'Out for delivery', time: 'Dispatched', completed: true),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'delivered':
        return [
          placed,
          OrderTimelineStep(title: 'Confirmed', time: 'Confirmed', completed: true),
          OrderTimelineStep(title: 'Out for delivery', time: 'Dispatched', completed: true),
          OrderTimelineStep(title: 'Delivered', time: 'Delivered', completed: true),
        ];
      case 'cancelled':
        return [
          placed,
          OrderTimelineStep(title: 'Cancelled', time: 'Cancelled', completed: true),
        ];
      case 'returned':
        return [
          placed,
          OrderTimelineStep(title: 'Returned', time: 'Returned', completed: true),
        ];
      default:
        return [placed];
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'pending').toString();
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    return Order(
      id: (json['id'] ?? '').toString(),
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      items: itemsJson.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      status: _mapStatus(rawStatus),
      rawStatus: rawStatus,
      address: _formatAddress(json['address']),
      paymentMethod: (json['payment_method'] ?? 'cod').toString(),
      paymentStatus: (json['payment_status'] ?? 'pending').toString(),
      itemTotal: (json['items_amount'] is num) ? (json['items_amount'] as num).round() : 0,
      deliveryFee: (json['delivery_charge'] is num) ? (json['delivery_charge'] as num).round() : 0,
      platformFee: 0,
      discount: (json['wallet_amount_used'] is num) ? (json['wallet_amount_used'] as num).round() : 0,
      timeline: _buildTimeline(rawStatus),
    );
  }
}
