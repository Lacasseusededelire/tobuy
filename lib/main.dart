import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importe les options Firebase générées par FlutterFire CLI
import 'firebase_options.dart';

// --- Imports des services et modèles ---
import 'package:tobuy/backend/services/auth_service.dart';
import 'package:tobuy/backend/services/firestore_service.dart'; // <-- IMPORT AJOUTÉ
import 'package:tobuy/models/to_buy_user.dart';

// --- Placeholders pour les futurs imports ---
// import 'package:tobuy/frontend/screens/login_screen.dart';
// import 'package:tobuy/frontend/screens/home_screen.dart';
// import 'package:tobuy/frontend/providers/theme_provider.dart';
// import 'package:tobuy/frontend/theme/app_theme.dart';
// import 'package:tobuy/ia/services/gemini_service.dart';
// import 'package:tobuy/frontend/providers/shopping_list_provider.dart';

// --- Fin des Placeholders ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supprimez le code de test temporaire s'il est encore là !

  runApp(
    MultiProvider(
      providers: [
        // Provider pour le service d'authentification (Membre 1)
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        // StreamProvider pour l'état de l'utilisateur (Membre 1)
        StreamProvider<ToBuyUser?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),

        // Provider pour le service Firestore (Membre 1)  <-- NOUVEAU PROVIDER AJOUTÉ
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),

        // --- Placeholders pour les Providers des autres membres ---
        // ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        // ChangeNotifierProvider<ShoppingListProvider>(create: (context) => ShoppingListProvider(context.read<AuthService>(), context.read<FirestoreService>())),
        // Provider<GeminiService>(create: (_) => GeminiService()),
        // --- Fin des Placeholders Providers ---
      ],
      child: const ToBuyApp(), // Widget racine de l'application
    ),
  );
}

// Widget racine de l'application
class ToBuyApp extends StatelessWidget {
  const ToBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToBuy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      // routes: { ... } // Seront ajoutées par Membre 2
    );
  }
}

// Widget pour gérer l'affichage en fonction de l'authentification
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final toBuyUser = Provider.of<ToBuyUser?>(context);

    if (toBuyUser != null) {
      // Utilisateur connecté -> Afficher HomeScreen (placeholder)
      // Exemple d'accès à FirestoreService depuis un widget enfant de AuthGate:
      // final firestoreService = context.read<FirestoreService>();
      print("Utilisateur connecté: ${toBuyUser.email}");
      return Scaffold(
          appBar: AppBar(title: const Text("ToBuy - Accueil")),
          body: Center(child: Text("Connecté! (${toBuyUser.email})\n(HomeScreen à venir)")));
    } else {
      // Utilisateur non connecté -> Afficher LoginScreen (placeholder)
      print("Utilisateur non connecté");
      return Scaffold(
          appBar: AppBar(title: const Text("ToBuy - Connexion")),
          body: const Center(child: Text("Non connecté\n(LoginScreen à venir)")));
    }
  }
}

// --- Widgets Placeholder (à supprimer par Membre 2) ---
// class LoginScreen extends StatelessWidget { ... }
// class HomeScreen extends StatelessWidget { ... }
// --- Fin Widgets Placeholder ---
