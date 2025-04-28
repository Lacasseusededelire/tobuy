import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:tobuy/ia/services/gemini_service.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:tobuy/models/suggestion.dart';
import 'package:tobuy/backend/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:tobuy/models/to_buy_user.dart';
import 'package:uuid/uuid.dart';

class ShoppingListProvider extends ChangeNotifier {
  ShoppingList? _list;
  List<Suggestion> _suggestions = [];
  final GeminiService _geminiService = GeminiService();
  final _uuid = const Uuid();

  ShoppingList? get list => _list;
  List<Suggestion> get suggestions => _suggestions;

  Future<void> loadList(BuildContext context, String listId) async {
    final firestoreService = context.read<FirestoreService>();
    final user = context.read<ToBuyUser?>();
    if (user == null) return;

    try {
      final lists = await firestoreService.getShoppingListsOnce(user.uid);
      _list = lists.firstWhere((list) => list.id == listId, orElse: () => ShoppingList(
            id: listId,
            userId: user.uid,
            items: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      await firestoreService.createShoppingList(_list!);
      await _fetchSuggestions();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement de la liste: $e');
    }
  }

  Future<void> addItem(BuildContext context, ShoppingItem item) async {
    final firestoreService = context.read<FirestoreService>();
    final user = context.read<ToBuyUser?>();
    if (user == null || _list == null) return;

    final itemWithId = item.id.isEmpty ? item.copyWith(id: _uuid.v4()) : item;
    print('Ajout de l\'article: ${itemWithId.name}');
    await firestoreService.addItemToList(_list!.id, itemWithId);
    _list = _list!.copyWith(
      items: [..._list!.items, itemWithId],
      updatedAt: DateTime.now(),
    );
    await _fetchSuggestions();
    await _updateWidget();
    notifyListeners();
  }

  Future<void> updateItem(BuildContext context, String itemId, ShoppingItem updatedItem) async {
    final firestoreService = context.read<FirestoreService>();
    final user = context.read<ToBuyUser?>();
    if (user == null || _list == null) return;

    print('Mise à jour de l\'article: ${updatedItem.name}');
    final index = _list!.items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      await firestoreService.updateItemInList(_list!.id, updatedItem);
      _list = _list!.copyWith(
        items: [
          ..._list!.items.sublist(0, index),
          updatedItem,
          ..._list!.items.sublist(index + 1),
        ],
        updatedAt: DateTime.now(),
      );
      await _fetchSuggestions();
      await _updateWidget();
      notifyListeners();
    }
  }

  Future<void> removeItem(BuildContext context, String itemId) async {
    final firestoreService = context.read<FirestoreService>();
    final user = context.read<ToBuyUser?>();
    if (user == null || _list == null) return;

    final item = _list!.items.firstWhere((i) => i.id == itemId);
    print('Suppression de l\'article: ${item.name}');
    await firestoreService.removeItemFromList(_list!.id, itemId);
    _list = _list!.copyWith(
      items: _list!.items.where((i) => i.id != itemId).toList(),
      updatedAt: DateTime.now(),
    );
    await _fetchSuggestions();
    await _updateWidget();
    notifyListeners();
  }

  Future<void> addSuggestion(BuildContext context, Suggestion suggestion) async {
    final item = ShoppingItem(
      id: _uuid.v4(),
      name: suggestion.name,
      quantity: 1.0,
      unitPrice: suggestion.estimatedPrice,
    );
    await addItem(context, item);
  }

  Future<void> _fetchSuggestions() async {
    if (_list == null) return;
    try {
      _suggestions = (await _geminiService.getSuggestions(_list!)).take(3).toList();
      print('Suggestions IA: ${_suggestions.map((s) => s.name).toList()}');
    } catch (e) {
      print('Erreur lors de l\'appel Gemini: $e');
      _suggestions = _list!.items.any((i) => i.name.toLowerCase() == 'okok')
          ? [
              Suggestion(
                name: 'Sucre',
                reason: 'Nécessaire pour l\'okok',
                estimatedPrice: 500.0,
              ),
            ]
          : [];
    }
    notifyListeners();
  }

  Future<List<ShoppingItem>> getRecipeIngredients(BuildContext context, double budget, String dish) async {
    try {
      final items = await _geminiService.getRecipeIngredients(budget, dish);
      return items.map((item) => item.id.isEmpty ? item.copyWith(id: _uuid.v4()) : item).toList();
    } catch (e) {
      print('Erreur lors de la récupération des ingrédients: $e');
      return [];
    }
  }

  Future<List<String>> getAutocomplete(BuildContext context, String query) async {
    try {
      return await _geminiService.getAutocomplete(query);
    } catch (e) {
      print('Erreur lors de l\'autocomplétion: $e');
      return [];
    }
  }

  Future<void> _updateWidget() async {
    final message = _list == null || _list!.items.isEmpty ? 'Aucun article' : '${_list!.items.length} article(s)';
    print('Mise à jour du widget: $message');
    await HomeWidget.saveWidgetData<String>('title', 'ToBuy Widget');
    await HomeWidget.saveWidgetData<String>('message', message);
    await HomeWidget.updateWidget(
      name: 'ToBuyWidget',
      androidName: 'ToBuyWidget',
    );
  }
}