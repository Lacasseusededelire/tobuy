import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:uuid/uuid.dart'; // Assurez-vous que uuid est dans pubspec.yaml

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _listsCollection = 'shopping_lists'; // Nom de la collection des listes
  final _uuid = const Uuid(); // Pour générer des IDs uniques pour les items

  // Référence à la collection des listes avec convertisseur pour utiliser nos objets Dart
  late final CollectionReference<ShoppingList> _listsRef;

  FirestoreService() {
     _listsRef = _firestore.collection(_listsCollection).withConverter<ShoppingList>(
          // Méthode pour lire depuis Firestore et convertir en objet ShoppingList
          fromFirestore: ShoppingList.fromFirestore,
          // Méthode pour convertir un objet ShoppingList en Map pour écrire dans Firestore
          toFirestore: (ShoppingList list, _) => list.toFirestore(),
        );
  }

  // --- Opérations sur les Listes d'Achats ---

  // Créer une nouvelle liste d'achats pour un utilisateur
  // L'objet ShoppingList doit déjà avoir un ID (généré avant l'appel) et le userId correct
  Future<void> createShoppingList(ShoppingList list) async {
    // Vérifications basiques avant écriture
    if (list.id.isEmpty || list.userId.isEmpty) {
       throw ArgumentError("L'ID de la liste et l'ID utilisateur ne peuvent pas être vides.");
    }
    try {
      print("Création de la liste ${list.id} pour l'utilisateur ${list.userId}");
      // Utilise l'ID fourni dans l'objet list comme ID de document
      await _listsRef.doc(list.id).set(list);
      print("Liste ${list.id} créée avec succès.");
    } catch (e) {
      print("Erreur lors de la création de la liste ${list.id}: $e");
      throw Exception("Impossible de créer la nouvelle liste d'achats.");
    }
  }

  // Mettre à jour une liste d'achats existante
  // Remplace complètement le document avec les nouvelles données de l'objet 'list'
  // Sauf si on utilise SetOptions(merge: true) qui fusionne les champs.
  // Ici, on met à jour la date 'updatedAt' avant d'écrire.
  Future<void> updateShoppingList(ShoppingList list) async {
     if (list.id.isEmpty) {
       throw ArgumentError("L'ID de la liste ne peut pas être vide pour une mise à jour.");
    }
    try {
      print("Mise à jour de la liste ${list.id}");
      // Met à jour la date de modification avant d'envoyer à Firestore
      final listWithTimestamp = list.copyWith(updatedAt: DateTime.now());
      // 'set' écrase le document existant avec les nouvelles données.
      // Utiliser 'update' si on veut seulement modifier certains champs.
      await _listsRef.doc(list.id).set(listWithTimestamp);
      print("Liste ${list.id} mise à jour avec succès.");
    } catch (e) {
      print("Erreur lors de la mise à jour de la liste ${list.id}: $e");
      throw Exception("Impossible de mettre à jour la liste d'achats.");
    }
  }

  // Récupérer un stream de toutes les listes d'achats d'un utilisateur spécifique
  // Le stream se met à jour automatiquement si les données changent dans Firestore
  Stream<List<ShoppingList>> getShoppingListsStream(String userId) {
    if (userId.isEmpty) {
      print("Avertissement: Tentative de récupérer un stream de listes sans userId.");
      return Stream.value([]); // Retourne un stream vide si pas d'userId
    }
    try {
      print("Récupération du stream des listes pour l'utilisateur $userId");
      return _listsRef
          .where('user_id', isEqualTo: userId) // Filtre par utilisateur
          .orderBy('updated_at', descending: true) // Trie par date de mise à jour (plus récentes en premier)
          .snapshots() // Récupère un stream de QuerySnapshot
          .map((snapshot) {
             print("Stream des listes mis à jour: ${snapshot.docs.length} listes trouvées.");
             // Mappe chaque DocumentSnapshot en objet ShoppingList grâce au converter
             return snapshot.docs.map((doc) => doc.data()).toList();
          })
          .handleError((error) {
             // Gestion des erreurs du stream
             print("Erreur dans le stream des listes pour $userId: $error");
             // On pourrait retourner un stream d'erreur ou un stream vide
             return <ShoppingList>[]; // Retourne une liste vide en cas d'erreur
          });
    } catch (e) {
      print("Erreur lors de la configuration du stream des listes pour $userId: $e");
      return Stream.error(Exception("Impossible de récupérer le stream des listes."));
    }
  }

   // Récupérer toutes les listes d'achats d'un utilisateur (une seule fois)
   Future<List<ShoppingList>> getShoppingListsOnce(String userId) async {
     if (userId.isEmpty) {
       throw ArgumentError("L'ID utilisateur ne peut pas être vide.");
     }
     try {
       print("Récupération ponctuelle des listes pour l'utilisateur $userId");
       final snapshot = await _listsRef
           .where('user_id', isEqualTo: userId)
           .orderBy('updated_at', descending: true)
           .get();
       print("${snapshot.docs.length} listes récupérées pour $userId.");
       return snapshot.docs.map((doc) => doc.data()).toList();
     } catch (e) {
       print("Erreur lors de la récupération ponctuelle des listes pour $userId: $e");
       throw Exception("Impossible de récupérer les listes d'achats.");
     }
   }

  // Supprimer une liste d'achats complète par son ID
  Future<void> deleteShoppingList(String listId) async {
    if (listId.isEmpty) {
       throw ArgumentError("L'ID de la liste ne peut pas être vide pour la suppression.");
    }
    try {
      print("Suppression de la liste $listId");
      await _listsRef.doc(listId).delete();
      print("Liste $listId supprimée avec succès.");
    } catch (e) {
      print("Erreur lors de la suppression de la liste $listId: $e");
      throw Exception("Impossible de supprimer la liste d'achats.");
    }
  }

  // --- Opérations sur les Items dans une Liste ---
  // Note: Ces méthodes lisent la liste entière, la modifient en mémoire, puis la réécrivent.
  // Pour de très grandes listes, des approches plus granulaires (comme FieldValue.arrayUnion/Remove
  // si la structure le permettait) ou des sous-collections seraient plus performantes.

  // Ajouter un élément à une liste spécifique
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    if (listId.isEmpty) throw ArgumentError("L'ID de la liste est requis.");
    if (item.name.isEmpty) throw ArgumentError("Le nom de l'item est requis.");

    try {
      print("Ajout de l'item '${item.name}' à la liste $listId");
      // Génère un ID unique pour l'item si celui fourni est vide
      final itemToAdd = item.id.isEmpty ? item.copyWith(id: _uuid.v4()) : item;

      // Utilisation d'une transaction pour lire et écrire de manière atomique
      await _firestore.runTransaction((transaction) async {
        final listDocRef = _listsRef.doc(listId);
        final listSnapshot = await transaction.get(listDocRef);

        if (!listSnapshot.exists) {
          throw Exception("Liste $listId non trouvée.");
        }

        // Récupère la liste actuelle (grâce au converter)
        ShoppingList currentList = listSnapshot.data()!;

        // Crée la nouvelle liste d'items en ajoutant le nouvel item
        final updatedItems = List<ShoppingItem>.from(currentList.items)..add(itemToAdd);

        // Crée l'objet ShoppingList mis à jour
        final updatedList = currentList.copyWith(
            items: updatedItems,
            updatedAt: DateTime.now() // Met à jour la date de modification
        );

        // Met à jour la liste dans Firestore via la transaction
        transaction.set(listDocRef, updatedList);
      });
      print("Item '${itemToAdd.name}' ajouté avec succès à la liste $listId.");

    } catch (e) {
      print("Erreur lors de l'ajout de l'item à la liste $listId: $e");
      throw Exception("Impossible d'ajouter l'élément à la liste.");
    }
  }

  // Supprimer un élément d'une liste spécifique par son ID d'item
  Future<void> removeItemFromList(String listId, String itemId) async {
    if (listId.isEmpty || itemId.isEmpty) {
      throw ArgumentError("L'ID de la liste et l'ID de l'item sont requis.");
    }
    try {
      print("Suppression de l'item $itemId de la liste $listId");
      await _firestore.runTransaction((transaction) async {
         final listDocRef = _listsRef.doc(listId);
         final listSnapshot = await transaction.get(listDocRef);

         if (!listSnapshot.exists) {
           throw Exception("Liste $listId non trouvée.");
         }

         ShoppingList currentList = listSnapshot.data()!;
         // Filtre la liste pour enlever l'item avec l'ID correspondant
         final updatedItems = currentList.items.where((item) => item.id != itemId).toList();

         // Vérifie si un item a réellement été supprimé avant de mettre à jour
         if (updatedItems.length < currentList.items.length) {
           final updatedList = currentList.copyWith(
               items: updatedItems,
               updatedAt: DateTime.now()
           );
           transaction.set(listDocRef, updatedList);
           print("Item $itemId supprimé avec succès de la liste $listId.");
         } else {
           print("Avertissement: Item $itemId non trouvé dans la liste $listId lors de la tentative de suppression.");
           // Pas besoin de mettre à jour si l'item n'a pas été trouvé
         }
      });
    } catch (e) {
      print("Erreur lors de la suppression de l'item $itemId de la liste $listId: $e");
      throw Exception("Impossible de supprimer l'élément de la liste.");
    }
  }

   // Mettre à jour un élément spécifique dans une liste
   // L'objet 'updatedItem' doit contenir l'ID de l'item à mettre à jour
   Future<void> updateItemInList(String listId, ShoppingItem updatedItem) async {
     if (listId.isEmpty || updatedItem.id.isEmpty) {
       throw ArgumentError("L'ID de la liste et l'ID de l'item à mettre à jour sont requis.");
     }
     try {
       print("Mise à jour de l'item ${updatedItem.id} ('${updatedItem.name}') dans la liste $listId");
       await _firestore.runTransaction((transaction) async {
          final listDocRef = _listsRef.doc(listId);
          final listSnapshot = await transaction.get(listDocRef);

          if (!listSnapshot.exists) {
            throw Exception("Liste $listId non trouvée.");
          }

          ShoppingList currentList = listSnapshot.data()!;
          // Trouve l'index de l'item à mettre à jour
          final itemIndex = currentList.items.indexWhere((item) => item.id == updatedItem.id);

          if (itemIndex != -1) {
            // Crée une nouvelle liste modifiable
            final updatedItems = List<ShoppingItem>.from(currentList.items);
            // Remplace l'ancien item par le nouveau à l'index trouvé
            updatedItems[itemIndex] = updatedItem;

            final updatedList = currentList.copyWith(
                items: updatedItems,
                updatedAt: DateTime.now()
            );
            transaction.set(listDocRef, updatedList);
            print("Item ${updatedItem.id} mis à jour avec succès dans la liste $listId.");
          } else {
            print("Avertissement: Item ${updatedItem.id} non trouvé dans la liste $listId pour mise à jour.");
            // Optionnel: Ajouter l'item s'il n'existe pas ? Ou lancer une erreur ?
            // throw Exception("Item ${updatedItem.id} non trouvé pour mise à jour.");
          }
       });
     } catch (e) {
       print("Erreur lors de la mise à jour de l'item ${updatedItem.id} dans la liste $listId: $e");
       throw Exception("Impossible de mettre à jour l'élément dans la liste.");
     }
   }
}
