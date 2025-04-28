import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias pour éviter conflit de nom User
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tobuy/models/to_buy_user.dart'; // Importer notre modèle utilisateur

class AuthService {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users'; // Nom de la collection Firestore

  // Obtient l'utilisateur Firebase actuel (peut être null)
  fb_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Stream pour écouter les changements d'état d'authentification Firebase
  // et les mapper vers notre modèle ToBuyUser (en allant chercher les infos dans Firestore)
  Stream<ToBuyUser?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      // Si l'utilisateur Firebase est null (déconnecté), retourne null
      if (firebaseUser == null) {
        return null;
      }
      try {
        // Récupérer le document utilisateur correspondant depuis Firestore
        final userDoc = await _firestore
            .collection(_usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          // Si le document existe, le convertir en objet ToBuyUser
          // Utilisation de .data() et cast explicite pour plus de sécurité
           final data = userDoc.data();
           if (data != null) {
              // Utilisation du factory constructor défini dans le modèle
              return ToBuyUser.fromFirestore(userDoc, null);
           } else {
              print("Erreur: Document utilisateur ${firebaseUser.uid} vide.");
              // Gérer ce cas: créer le doc? retourner null?
              return await _createFirestoreUserEntry(firebaseUser); // Tentative de création
           }
        } else {
          // Cas où l'utilisateur est authentifié mais n'a pas (encore) d'entrée dans Firestore
          print("Avertissement: Utilisateur ${firebaseUser.uid} authentifié mais non trouvé dans Firestore. Création de l'entrée.");
          // Créer l'entrée dans Firestore
          return await _createFirestoreUserEntry(firebaseUser);
        }
      } catch (e) {
        print("Erreur lors de la récupération/création de l'utilisateur Firestore: $e");
        // En cas d'erreur Firestore, on pourrait retourner null ou lancer une exception
        return null;
      }
    });
  }

  // Méthode privée pour créer l'entrée utilisateur dans Firestore
  Future<ToBuyUser?> _createFirestoreUserEntry(fb_auth.User firebaseUser) async {
    final newUser = ToBuyUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? 'email.inconnu@example.com', // Fournir un email par défaut si null
      createdAt: DateTime.now(),
    );
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(newUser.uid)
          .set(newUser.toFirestore());
      print("Entrée Firestore créée pour ${newUser.uid}");
      return newUser;
    } catch (e) {
      print("Erreur lors de la création de l'entrée Firestore pour ${newUser.uid}: $e");
      return null; // Échec de la création
    }
  }


  // Créer un nouvel utilisateur avec email et mot de passe
  Future<ToBuyUser?> createUser({required String email, required String password}) async {
    try {
      // 1. Créer l'utilisateur dans Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Si la création Auth réussit, créer l'entrée dans Firestore
      if (userCredential.user != null) {
        print("Utilisateur créé dans Firebase Auth: ${userCredential.user!.uid}");
        // Utilise la méthode privée pour créer l'entrée Firestore
        return await _createFirestoreUserEntry(userCredential.user!);
      } else {
        print("Erreur: userCredential.user est null après création.");
        return null; // Ne devrait pas arriver si createUserWithEmailAndPassword réussit
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      // Gérer les erreurs spécifiques de Firebase Auth
      print("Erreur FirebaseAuth lors de la création: ${e.code} - ${e.message}");
      // Relancer une exception plus conviviale pour l'UI
      throw Exception(_mapAuthErrorCodeToMessage(e.code));
    } catch (e) {
      print("Erreur inconnue lors de la création utilisateur: $e");
      throw Exception("Une erreur inconnue est survenue lors de l'inscription.");
    }
  }

  // Connecter un utilisateur existant avec email et mot de passe
  Future<ToBuyUser?> signIn({required String email, required String password}) async {
    try {
      // 1. Connecter l'utilisateur via Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Si la connexion Auth réussit, récupérer les données depuis Firestore
      if (userCredential.user != null) {
         print("Utilisateur connecté via Firebase Auth: ${userCredential.user!.uid}");
         // Récupérer les données de Firestore (le stream 'user' le fera aussi, mais ici c'est immédiat)
         final userDoc = await _firestore.collection(_usersCollection).doc(userCredential.user!.uid).get();
         if (userDoc.exists) {
           final data = userDoc.data();
           if (data != null) {
             return ToBuyUser.fromFirestore(userDoc, null);
           } else {
              print("Erreur: Document utilisateur ${userCredential.user!.uid} vide après connexion.");
              // Tenter de recréer l'entrée? Déconnecter?
              await _firebaseAuth.signOut();
              throw Exception("Profil utilisateur corrompu.");
           }
         } else {
            // Cas très improbable: connecté mais pas de doc Firestore
            print("Erreur: Utilisateur ${userCredential.user!.uid} connecté mais non trouvé dans Firestore après connexion.");
            // Déconnecter pour sécurité
            await _firebaseAuth.signOut();
            throw Exception("Profil utilisateur introuvable après connexion.");
         }
       } else {
         print("Erreur: userCredential.user est null après connexion.");
         return null; // Ne devrait pas arriver si signInWithEmailAndPassword réussit
       }
    } on fb_auth.FirebaseAuthException catch (e) {
      print("Erreur FirebaseAuth lors de la connexion: ${e.code} - ${e.message}");
      throw Exception(_mapAuthErrorCodeToMessage(e.code));
    } catch (e) {
      print("Erreur inconnue lors de la connexion: $e");
      throw Exception("Une erreur inconnue est survenue lors de la connexion.");
    }
  }

  // Déconnecter l'utilisateur actuel
  Future<void> signOut() async {
    try {
      print("Déconnexion de l'utilisateur...");
      await _firebaseAuth.signOut();
      print("Utilisateur déconnecté.");
    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
      // Gérer l'erreur si nécessaire, mais souvent on peut continuer
    }
  }

  // Récupérer l'utilisateur ToBuy connecté actuel (méthode ponctuelle)
  // Utile si on n'écoute pas le stream
  Future<ToBuyUser?> getCurrentUser() async {
     final firebaseUser = _firebaseAuth.currentUser;
     if (firebaseUser == null) {
       return null; // Pas d'utilisateur connecté
     }
     // Récupérer les données Firestore associées
     try {
        final userDoc = await _firestore.collection(_usersCollection).doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
             return ToBuyUser.fromFirestore(userDoc, null);
          }
        }
        // Si le doc n'existe pas ou est vide, retourne null (ou gère l'erreur)
        print("Avertissement: getCurrentUser - Utilisateur ${firebaseUser.uid} authentifié mais données Firestore absentes/vides.");
        return null;
     } catch (e) {
        print("Erreur Firestore dans getCurrentUser: $e");
        return null;
     }
  }

  // Helper pour traduire les codes d'erreur Firebase Auth en messages
  String _mapAuthErrorCodeToMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'L\'adresse e-mail n\'est pas valide.';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé.';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé pour cet e-mail.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cette adresse e-mail est déjà utilisée par un autre compte.';
      case 'operation-not-allowed':
        return 'L\'authentification par e-mail/mot de passe n\'est pas activée.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      // Ajoutez d'autres codes d'erreur si nécessaire
      default:
        return 'Une erreur d\'authentification est survenue ($code).';
    }
  }
}
