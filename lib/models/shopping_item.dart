import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id; // ID unique de l'item DANS la liste (peut être généré par uuid)
  final String name;
  final double quantity; // Garder double pour flexibilité (ex: 1.5 kg)
  final double unitPrice;
  final double totalItemPrice; // Calculé : quantity * unitPrice

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  }) : totalItemPrice = quantity * unitPrice; // Calcul automatique

  // Factory pour créer depuis une Map (utile pour lire depuis Firestore)
  // L'ID est passé séparément car il n'est pas toujours dans la map elle-même
  factory ShoppingItem.fromMap(Map<String, dynamic> map, String id) {
    return ShoppingItem(
      id: id,
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      // totalItemPrice est recalculé dans le constructeur
    );
  }

   // Factory pour créer depuis un DocumentSnapshot Firestore (si stocké en sous-collection)
   // Non utilisé dans notre structure actuelle (items dans un tableau) mais utile si ça change
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


  // Méthode pour convertir en Map (utile pour écrire dans Firestore)
  Map<String, dynamic> toMap() {
    return {
      // L'ID n'est pas forcément stocké dans la map si généré à la volée
      // 'id': id, // Décommenter si vous voulez stocker l'ID dans le tableau
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_item_price': totalItemPrice, // Stocker le total calculé
    };
  }

   // Méthode pour convertir en Map pour Firestore (si stocké en sous-collection)
   // Non utilisé dans notre structure actuelle
   Map<String, dynamic> toFirestore() {
     return toMap(); // Réutilise la logique de toMap
   }

  // Méthode CopyWith pour faciliter les mises à jour immuables
  ShoppingItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
  }) {
    // Recalcule le prix total si quantité ou prix unitaire change
    final newQuantity = quantity ?? this.quantity;
    final newUnitPrice = unitPrice ?? this.unitPrice;
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: newQuantity,
      unitPrice: newUnitPrice,
      // totalItemPrice est recalculé automatiquement
    );
  }

  // Méthode toString pour faciliter le débogage
  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, quantity: $quantity, unitPrice: $unitPrice, totalItemPrice: $totalItemPrice)';
  }
}
