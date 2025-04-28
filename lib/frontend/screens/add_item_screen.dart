import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobuy/frontend/providers/shopping_list_provider.dart';
import 'package:tobuy/models/shopping_item.dart';
import 'package:uuid/uuid.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  List<String> _autocompleteSuggestions = [];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchAutocompleteSuggestions(String query) async {
    final provider = context.read<ShoppingListProvider>();
    if (query.isNotEmpty) {
      final suggestions = await provider.getAutocomplete(context, query);
      setState(() {
        _autocompleteSuggestions = suggestions;
      });
    } else {
      setState(() {
        _autocompleteSuggestions = [];
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ShoppingListProvider>();
      final item = ShoppingItem(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        quantity: double.tryParse(_quantityController.text) ?? 1.0,
        unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
      );
      provider.addItem(context, item);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un article'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text;
                  _fetchAutocompleteSuggestions(query);
                  return _autocompleteSuggestions;
                },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _nameController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'article',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Veuillez entrer une quantité valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire (FCFA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Veuillez entrer un prix valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48.0),
                ),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}