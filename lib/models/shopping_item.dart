import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalItemPrice;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  }) : totalItemPrice = quantity * unitPrice;

  factory ShoppingItem.fromMap(Map<String, dynamic> map, String id) {
    return ShoppingItem(
      id: id,
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory ShoppingItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError("Données manquantes pour ShoppingItem ${snapshot.id}");
    }
    return ShoppingItem(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (data['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_item_price': totalItemPrice,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_item_price': totalItemPrice,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, quantity: $quantity, unitPrice: $unitPrice, totalItemPrice: $totalItemPrice)';
  }
}