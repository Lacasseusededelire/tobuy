import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobuy/frontend/providers/shopping_list_provider.dart';
import 'package:tobuy/frontend/widgets/shopping_item_card.dart';
import 'package:tobuy/frontend/widgets/suggestion_card.dart';
import 'package:tobuy/frontend/widgets/total_price_display.dart';
import 'package:tobuy/frontend/widgets/theme_toggle_button.dart';
import 'package:tobuy/frontend/screens/add_item_screen.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:tobuy/models/suggestion.dart';
import 'package:tobuy/models/to_buy_user.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/backend/services/auth_service.dart';
import 'package:tobuy/backend/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pipChannel = MethodChannel('com.example.tobuy/pip');
  final _searchController = TextEditingController();
  String _selectedListId = 'default_list';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ShoppingListProvider>();
      provider.loadList(context, _selectedListId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _enterPipMode() async {
    try {
      await _pipChannel.invokeMethod('enterPipMode');
      print('Mode PiP déclenché');
    } catch (e) {
      print('Erreur PiP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PiP: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    final authService = context.read<AuthService>();
    await authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showRecipeDialog(BuildContext context, ShoppingListProvider provider) {
    final dishController = TextEditingController();
    final budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Suggérer des ingrédients'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dishController,
                decoration: const InputDecoration(
                  labelText: 'Plat (ex. Ndolé)',
                ),
              ),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (FCFA)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final dish = dishController.text.trim();
                final budget = double.tryParse(budgetController.text.trim()) ?? 1000.0;
                if (dish.isNotEmpty) {
                  final items = await provider.getRecipeIngredients(context, budget, dish);
                  for (var item in items) {
                    await provider.addItem(context, item);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ToBuyUser?>(context);
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = Provider.of<ShoppingListProvider>(context);
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<ShoppingList>>(
      stream: firestoreService.getShoppingListsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Erreur: ${snapshot.error}')));
        }

        final currentList = provider.list;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ma Liste d\'Achats'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_in_picture),
                onPressed: _enterPipMode,
              ),
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Rechercher un aliment',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        // _searchQuery utilisé ici pour filtrer dans le futur
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Liste de courses (${currentList?.items.length ?? 0})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentList?.items.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = currentList!.items[index];
                    return ShoppingItemCard(
                      item: item,
                      onDelete: () => provider.removeItem(context, item.id),
                    );
                  },
                ),
                if (currentList != null && provider.suggestions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'Suggestions IA',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = provider.suggestions[index];
                          return SuggestionCard(
                            suggestion: suggestion,
                            onAccept: () => provider.addSuggestion(context, suggestion),
                          );
                        },
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48.0),
                    ),
                    onPressed: () {
                      _showRecipeDialog(context, provider);
                    },
                    child: const Text('Suggérer des ingrédients pour un plat'),
                  ),
                ),
                TotalPriceDisplay(totalPrice: currentList?.totalPrice ?? 0.0),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AddItemScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeScaleTransition(animation: animation, child: child);
                  },
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}