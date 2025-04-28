import 'package:cloud_firestore/cloud_firestore.dart';
import 'shopping_item.dart';

class ShoppingList {
  final String id;
  final String userId;
  final List<ShoppingItem> items;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  }) : totalPrice = items.fold(0.0, (sum, item) => sum + item.totalItemPrice);

  factory ShoppingList.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError("Données manquantes pour ShoppingList ${snapshot.id}");
    }
    final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];
    final List<ShoppingItem> itemsList = itemsData.asMap().entries.map((entry) {
      final index = entry.key;
      if (entry.value is Map<String, dynamic>) {
        final itemMap = entry.value as Map<String, dynamic>;
        final itemId = itemMap['id'] as String? ?? '${snapshot.id}_item_$index';
        return ShoppingItem.fromMap(itemMap, itemId);
      } else {
        print("Élément invalide dans la liste d'items pour ${snapshot.id} à l'index $index: ${entry.value}");
        return ShoppingItem(id: '${snapshot.id}_invalid_$index', name: 'Erreur Item', quantity: 0, unitPrice: 0);
      }
    }).toList();

    return ShoppingList(
      id: snapshot.id,
      userId: data['user_id'] as String? ?? '',
      items: itemsList,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'total_price': totalPrice,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      items: (map['items'] as List<dynamic>)
          .map((item) => ShoppingItem.fromMap(item as Map<String, dynamic>, item['id'] as String))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ShoppingList copyWith({
    String? id,
    String? userId,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, userId: $userId, items: ${items.length} items, totalPrice: $totalPrice, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}