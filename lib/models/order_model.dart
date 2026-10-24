import '../services/api_service.dart';

enum OrderStatus { active, delivered, cancelled }

String _imageHost() => ApiService.baseUrl.replaceAll('/api/v1', '');

String _resolveImage(String? raw) {
  final url = (raw ?? '').toString();
  if (url.isEmpty) return '';
  // Some seed/admin data stores a bundled Flutter asset path (e.g.
  // "assets/images/products/vegetable1.png") instead of a real uploaded
  // image URL. That path must be left as-is for Image.asset() to load it -
  // prefixing it with the API host turns it into a broken network URL,
  // which is why Carrot/Cucumber showed no image while uploaded-image
  // products did.
  if (url.startsWith('http') || url.startsWith('assets/')) return url;
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
      id: (json['id'] is num)
          ? (json['id'] as num).toInt()
          : (int.tryParse(json['id'].toString()) ?? 0),
      productId: rawProductId is int
          ? rawProductId
          : (rawProductId is num
                ? rawProductId.toInt()
                : int.tryParse(rawProductId?.toString() ?? '')),
      name: (product['name'] ?? 'Item').toString(),
      image: _resolveImage(product['image_url']?.toString()),
      unit: '1 unit',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : (int.tryParse(json['quantity']?.toString() ?? '') ?? 1),
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
  final DateTime? deliveredAt;

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
    this.deliveredAt,
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
      case 'refunded':
        return 'Refunded';
      case 'failed':
        return 'Failed';
      default:
        return const {
              'picking': 'Preparing your order',
              'picked': 'Preparing your order',
              'packing': 'Preparing your order',
              'packed': 'Preparing your order',
              'ready_for_dispatch': 'Ready for dispatch',
              'handed_over': 'Out for delivery',
            }[rawStatus] ??
            rawStatus;
    }
  }

  static OrderStatus _mapStatus(String raw) {
    if (raw == 'refunded') return OrderStatus.delivered;
    if (raw == 'failed') return OrderStatus.cancelled;
    return _mapStatusBase(raw);
  }

  static OrderStatus _mapStatusBase(String raw) {
    switch (raw) {
      case 'delivered':
      case 'returned':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.active;
    }
  }

  static String _formatAddress(dynamic addr) {
    if (addr is! Map) return '';
    final parts =
        [
              addr['line1'],
              addr['line2'],
              addr['city'],
              addr['state'],
              addr['pincode'],
            ]
            .where((p) => p != null && p.toString().trim().isNotEmpty)
            .map((p) => p.toString());
    return parts.join(', ');
  }

  static List<OrderTimelineStep> _buildTimeline(String status) {
    final placed = OrderTimelineStep(
      title: 'Order placed',
      time: 'Placed',
      completed: true,
    );
    if (status == 'refunded') {
      return [
        placed,
        OrderTimelineStep(title: 'Refunded', time: 'Refunded', completed: true),
      ];
    }
    if (status == 'failed') {
      return [
        placed,
        OrderTimelineStep(title: 'Failed', time: 'Failed', completed: true),
      ];
    }
    switch (status) {
      case 'pending':
        return [
          placed,
          OrderTimelineStep(title: 'Confirmed', time: null, completed: false),
          OrderTimelineStep(
            title: 'Out for delivery',
            time: null,
            completed: false,
          ),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'confirmed':
        return [
          placed,
          OrderTimelineStep(
            title: 'Confirmed',
            time: 'Confirmed',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Out for delivery',
            time: null,
            completed: false,
          ),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'picking':
      case 'picked':
      case 'packing':
      case 'packed':
        return [
          placed,
          OrderTimelineStep(
            title: 'Confirmed',
            time: 'Confirmed',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Preparing your order',
            time: 'Preparing',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Out for delivery',
            time: null,
            completed: false,
          ),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'ready_for_dispatch':
      case 'handed_over':
      case 'shipped':
        return [
          placed,
          OrderTimelineStep(
            title: 'Confirmed',
            time: 'Confirmed',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Preparing your order',
            time: 'Preparing',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Out for delivery',
            time: 'Dispatched',
            completed: true,
          ),
          OrderTimelineStep(title: 'Delivered', time: null, completed: false),
        ];
      case 'delivered':
        return [
          placed,
          OrderTimelineStep(
            title: 'Confirmed',
            time: 'Confirmed',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Preparing your order',
            time: 'Preparing',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Out for delivery',
            time: 'Dispatched',
            completed: true,
          ),
          OrderTimelineStep(
            title: 'Delivered',
            time: 'Delivered',
            completed: true,
          ),
        ];
      case 'cancelled':
        return [
          placed,
          OrderTimelineStep(
            title: 'Cancelled',
            time: 'Cancelled',
            completed: true,
          ),
        ];
      case 'returned':
        return [
          placed,
          OrderTimelineStep(
            title: 'Returned',
            time: 'Returned',
            completed: true,
          ),
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
      date:
          (DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                  DateTime.now())
              .toLocal(),
      items: itemsJson
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: _mapStatus(rawStatus),
      rawStatus: rawStatus,
      address: _formatAddress(json['address']),
      paymentMethod: (json['payment_method'] ?? 'cod').toString(),
      paymentStatus: (json['payment_status'] ?? 'pending').toString(),
      itemTotal: itemsJson.fold<int>(
        0,
        (sum, e) =>
            sum +
            (((e as Map<String, dynamic>)['price'] is num
                ? ((e['price'] as num) *
                          ((e['quantity'] is num) ? (e['quantity'] as num) : 1))
                      .round()
                : 0)),
      ),
      deliveryFee: (json['delivery_charge'] is num)
          ? (json['delivery_charge'] as num).round()
          : 0,
      platformFee: (json['platform_fee'] is num)
          ? (json['platform_fee'] as num).round()
          : 0,
      discount:
          ((json['wallet_amount_used'] is num)
              ? (json['wallet_amount_used'] as num).round()
              : 0) +
          ((json['coupon_discount'] is num)
              ? (json['coupon_discount'] as num).round()
              : 0),
      timeline: _buildTimeline(rawStatus),
      deliveredAt: DateTime.tryParse(
        json['delivered_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}
