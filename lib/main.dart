import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importe les options Firebase générées par FlutterFire CLI
// Assurez-vous que ce fichier existe après avoir exécuté `flutterfire configure`
import 'firebase_options.dart';

// --- Imports des services et modèles (Assurez-vous que ces fichiers existent aux bons endroits) ---
import 'package:tobuy/backend/services/auth_service.dart';
import 'package:tobuy/models/to_buy_user.dart';

// --- Placeholders pour les futurs imports (gérés par Membre 2 et 3) ---
// import 'package:tobuy/frontend/screens/login_screen.dart';
// import 'package:tobuy/frontend/screens/home_screen.dart';
// import 'package:tobuy/frontend/providers/theme_provider.dart';
// import 'package:tobuy/frontend/theme/app_theme.dart';
// import 'package:tobuy/ia/services/gemini_service.dart'; // Exemple pour IA
// import 'package:tobuy/frontend/providers/shopping_list_provider.dart'; // Exemple pour listes

// --- Fin des Placeholders ---

void main() async {
  // Étape 1: Assurer l'initialisation des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Étape 2: Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Étape 3: Lancer l'application Flutter avec les Providers
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

        // --- Placeholders pour les Providers des autres membres ---
        // ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        // ChangeNotifierProvider<ShoppingListProvider>(create: (context) => ShoppingListProvider(context.read<AuthService>())),
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
    // --- Récupération des Providers (Exemple pour le thème - sera fait par Membre 2) ---
    // final themeProvider = Provider.of<ThemeProvider>(context); // Exemple

    return MaterialApp(
      title: 'ToBuy', // Sera mis dans constants/strings.dart par Membre 2
      debugShowCheckedModeBanner: false,

      // --- Gestion du Thème (Sera géré par Membre 2 via ThemeProvider) ---
      theme: ThemeData.light(useMaterial3: true), // Thème light de base
      darkTheme: ThemeData.dark(useMaterial3: true), // Thème dark de base
      themeMode: ThemeMode.system, // Thème système par défaut
      // theme: AppTheme.lightTheme, // Exemple d'appel au thème light défini par Membre 2
      // darkTheme: AppTheme.darkTheme, // Exemple d'appel au thème dark défini par Membre 2
      // themeMode: themeProvider.themeMode, // Exemple: le mode est contrôlé par le provider
      // --- Fin Gestion du Thème ---

      // --- Logique d'affichage initial (AuthGate) ---
      home: const AuthGate(),

      // --- Routes (Seront définies par Membre 2) ---
      // routes: {
      //   '/login': (context) => const LoginScreen(),
      //   '/register': (context) => const RegisterScreen(),
      //   '/home': (context) => const HomeScreen(),
      // },
      // --- Fin Routes ---
    );
  }
}

// Widget pour gérer l'affichage en fonction de l'authentification
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupère l'état de l'utilisateur depuis le StreamProvider
    final toBuyUser = Provider.of<ToBuyUser?>(context);

    // Si l'utilisateur est connecté
    if (toBuyUser != null) {
      // Affiche l'écran d'accueil (HomeScreen - à implémenter par Membre 2)
      // return const HomeScreen(); // Décommenter quand HomeScreen existe
      print("Utilisateur connecté: ${toBuyUser.email}"); // Log pour vérifier
      return Scaffold(
          appBar: AppBar(title: const Text("ToBuy - Accueil")),
          body: Center(child: Text("Connecté! (${toBuyUser.email})\n(HomeScreen à venir)"))); // Placeholder
    }
    // Sinon (utilisateur non connecté)
    else {
      // Affiche l'écran de connexion (LoginScreen - à implémenter par Membre 2)
      // return const LoginScreen(); // Décommenter quand LoginScreen existe
      print("Utilisateur non connecté"); // Log pour vérifier
      return Scaffold(
          appBar: AppBar(title: const Text("ToBuy - Connexion")),
          body: const Center(child: Text("Non connecté\n(LoginScreen à venir)"))); // Placeholder
    }
  }
}

// --- Widgets Placeholder (à supprimer par Membre 2) ---
// class LoginScreen extends StatelessWidget { ... }
// class HomeScreen extends StatelessWidget { ... }
// --- Fin Widgets Placeholder ---
