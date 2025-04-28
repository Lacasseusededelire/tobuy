import 'package:cloud_firestore/cloud_firestore.dart';
import 'shopping_item.dart'; // Importer le modèle ShoppingItem

class ShoppingList {
  final String id; // ID unique de la liste (ID du document Firestore)
  final String userId; // Référence à l'utilisateur propriétaire
  final List<ShoppingItem> items;
  final double totalPrice; // Calculé à partir des items
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    // Le prix total est calculé automatiquement à partir de la liste d'items fournie
  }) : totalPrice = items.fold(0.0, (sum, item) => sum + item.totalItemPrice);

  // Factory pour créer depuis Firestore
  factory ShoppingList.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
     if (data == null) {
        throw StateError("Données manquantes pour ShoppingList ${snapshot.id}");
     }

    // Traitement du tableau 'items'
    final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];
    final List<ShoppingItem> itemsList = itemsData.asMap().entries.map((entry) {
       final index = entry.key;
       // Assure que chaque élément du tableau est bien une Map
       if (entry.value is Map<String, dynamic>) {
         final itemMap = entry.value as Map<String, dynamic>;
         // Utilise l'ID stocké dans la map s'il existe, sinon génère un ID basé sur l'index
         // NOTE: Il est préférable de stocker un ID unique (généré par uuid) dans la map lors de l'ajout
         final itemId = itemMap['id'] as String? ?? '${snapshot.id}_item_$index';
         return ShoppingItem.fromMap(itemMap, itemId);
       } else {
         // Gère le cas où un élément du tableau n'est pas une Map valide
         print("Élément invalide dans la liste d'items pour ${snapshot.id} à l'index $index: ${entry.value}");
         // Retourne un item vide ou lance une erreur selon la robustesse souhaitée
         return ShoppingItem(id: '${snapshot.id}_invalid_$index', name: 'Erreur Item', quantity: 0, unitPrice: 0);
       }
    }).toList();


    return ShoppingList(
      id: snapshot.id,
      userId: data['user_id'] as String? ?? '',
      items: itemsList,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // totalPrice est recalculé dans le constructeur
    );
  }

  // Méthode pour convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      // Convertit la liste de ShoppingItem en liste de Maps
      'items': items.map((item) => item.toMap()).toList(),
      'total_price': totalPrice, // Stocker le total calculé
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt), // Sera souvent mis à jour par le service
    };
  }

   // Méthode CopyWith pour faciliter les mises à jour immuables
   ShoppingList copyWith({
     String? id,
     String? userId,
     List<ShoppingItem>? items,
     DateTime? createdAt,
     DateTime? updatedAt,
   }) {
     // Si la liste d'items change, le prix total est recalculé automatiquement
     return ShoppingList(
       id: id ?? this.id,
       userId: userId ?? this.userId,
       items: items ?? this.items,
       createdAt: createdAt ?? this.createdAt,
       updatedAt: updatedAt ?? this.updatedAt,
     );
   }

   // Méthode toString pour faciliter le débogage
   @override
   String toString() {
     return 'ShoppingList(id: $id, userId: $userId, items: ${items.length} items, totalPrice: $totalPrice, createdAt: $createdAt, updatedAt: $updatedAt)';
   }
}

