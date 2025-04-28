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

  factory ToBuyUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError("Données manquantes pour ToBuyUser ${snapshot.id}");
    }
    return ToBuyUser(
      uid: snapshot.id,
      email: data['email'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ToBuyUser.fromMap(Map<String, dynamic> map) {
    return ToBuyUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'ToBuyUser(uid: $uid, email: $email, createdAt: $createdAt)';
  }
}