import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:background_fetch/background_fetch.dart';
import 'firebase_options.dart';
import 'frontend/theme/app_theme.dart';
import 'frontend/providers/theme_provider.dart';
import 'frontend/providers/shopping_list_provider.dart';
import 'frontend/screens/login_screen.dart';
import 'frontend/screens/register_screen.dart';
import 'frontend/screens/home_screen.dart';
import 'frontend/screens/add_item_screen.dart';
import 'frontend/screens/edit_item_screen.dart';
import 'backend/services/auth_service.dart';
import 'backend/services/firestore_service.dart';
import 'models/to_buy_user.dart';
import 'models/shopping_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
      requiredNetworkType: NetworkType.ANY,
    ),
    (String taskId) async {
      final provider = ShoppingListProvider();
      final message = provider.list?.items.isEmpty ?? true ? 'Aucun article' : '${provider.list!.items.length} article(s)';
      await HomeWidget.saveWidgetData<String>('title', 'ToBuy Widget');
      await HomeWidget.saveWidgetData<String>('message', message);
      await HomeWidget.updateWidget(name: 'ToBuyWidget', androidName: 'ToBuyWidget');
      BackgroundFetch.finish(taskId);
    },
  ).then((int status) {
    print('[BackgroundFetch] configure success: $status');
  }).catchError((e) {
    print('[BackgroundFetch] configure ERROR: $e');
  });

  runApp(const ToBuyApp());
}

class ToBuyApp extends StatelessWidget {
  const ToBuyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<ShoppingListProvider>(create: (_) => ShoppingListProvider()),
        StreamProvider<ToBuyUser?>.value(
          value: AuthService().user,
          initialData: null,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ToBuy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/add-item': (context) => const AddItemScreen(),
              '/edit-item': (context) => EditItemScreen(
                    item: ModalRoute.of(context)!.settings.arguments as ShoppingItem,
                  ),
            },
          );
        },
      ),
    );
  }
}