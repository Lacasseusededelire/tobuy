import 'package:cloud_firestore/cloud_firestore.dart';

class ToBuyUser {
  final String uid;
  final String email;
  final DateTime createdAt;

  ToBuyUser({
    required this.uid,
    required this.email,
    required this.createdAt,
  });

  // Factory constructor pour créer une instance depuis Firestore
  factory ToBuyUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    // Vérification pour robustesse
    if (data == null) {
      throw StateError("Données manquantes pour ToBuyUser ${snapshot.id}");
    }
    return ToBuyUser(
      uid: snapshot.id, // Utilise l'ID du document comme uid
      email: data['email'] as String? ?? '', // Cast explicite et valeur par défaut
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(), // Cast explicite
    );
  }

  // Méthode pour convertir une instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      // L'uid n'est pas stocké dans les champs, c'est l'ID du document
      'email': email,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  // Méthode toString pour faciliter le débogage
  @override
  String toString() {
    return 'ToBuyUser(uid: $uid, email: $email, createdAt: $createdAt)';
  }
}
