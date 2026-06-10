class BillItemModel {
  final String name;
  final double price;
  final int qty;
  final List<String> orderedBy;

  BillItemModel({
    required this.name,
    required this.price,
    required this.qty,
    required this.orderedBy,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'qty': qty,
    'orderedBy': orderedBy,
  };

  factory BillItemModel.fromMap(Map<String, dynamic> map) => BillItemModel(
    name: map['name'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    qty: map['qty'] ?? 1,
    orderedBy: List<String>.from(map['orderedBy'] ?? []),
  );
}

class BillModel {
  final String id;
  final String title;
  final double totalAmount;
  final String createdBy;
  final List<String> members;
  final List<BillItemModel> items;
  final double taxPercent;
  final double servicePercent;
  final String status;
  final DateTime createdAt;

  BillModel({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.createdBy,
    required this.members,
    this.items = const [],
    this.taxPercent = 0,
    this.servicePercent = 0,
    this.status = 'unpaid',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'totalAmount': totalAmount,
    'createdBy': createdBy,
    'members': members,
    'items': items.map((i) => i.toMap()).toList(),
    'taxPercent': taxPercent,
    'servicePercent': servicePercent,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BillModel.fromMap(Map<String, dynamic> map) => BillModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    totalAmount: (map['totalAmount'] ?? 0).toDouble(),
    createdBy: map['createdBy'] ?? '',
    members: List<String>.from(map['members'] ?? []),
    items: (map['items'] as List<dynamic>? ?? [])
        .map((i) => BillItemModel.fromMap(i))
        .toList(),
    taxPercent: (map['taxPercent'] ?? 0).toDouble(),
    servicePercent: (map['servicePercent'] ?? 0).toDouble(),
    status: map['status'] ?? 'unpaid',
    createdAt: DateTime.parse(map['createdAt']),
  );

  // Hitung subtotal dari semua item
  double get subtotal =>
      items.fold(0, (sum, item) => sum + (item.price * item.qty));

  // Hitung pajak
  double get taxAmount => subtotal * (taxPercent / 100);

  // Hitung service
  double get serviceAmount => subtotal * (servicePercent / 100);

  // Grand total
  double get grandTotal => subtotal + taxAmount + serviceAmount;

  // Hitung tagihan per orang
  Map<String, double> get billPerPerson {
    final Map<String, double> result = {};
    for (final member in [...members, 'Kamu']) {
      result[member] = 0;
    }
    for (final item in items) {
      if (item.orderedBy.isEmpty) continue;
      final sharePerPerson = (item.price * item.qty) / item.orderedBy.length;
      for (final person in item.orderedBy) {
        result[person] = (result[person] ?? 0) + sharePerPerson;
      }
    }
    // Tambah pajak + service proporsional
    final total = subtotal == 0 ? 1 : subtotal;
    result.forEach((key, value) {
      final proportion = value / total;
      result[key] = value +
          (taxAmount * proportion) +
          (serviceAmount * proportion);
    });
    return result;
  }
}