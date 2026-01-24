import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const CategorySelectionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends ConsumerState<CategorySelectionScreen> {
  final Set<String> _selectedCategoryIds = {};
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ref.read(apiServiceProvider).getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar categorias: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        if (_selectedCategoryIds.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Limite de 5 categorias atingido!"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          _selectedCategoryIds.add(id);
        }
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedCategoryIds.length != 5) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(apiServiceProvider).updateSessionCategories(
        widget.sessionId,
        _selectedCategoryIds.toList(),
      );
      if (mounted) {
        // Navigate to lobby (placeholder for now, or just go back for demo)
        Navigator.of(context).pushReplacementNamed('/lobby'); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar categorias: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SELECIONE 5 CATEGORIAS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategoryIds.contains(cat.id);
                      return _buildCategoryCard(cat, isSelected);
                    },
                  ),
                ),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildCategoryCard(Category category, bool isSelected) {
    final baseColor = Color(int.parse(category.hexColor.replaceFirst('#', '0xFF')));
    
    return GestureDetector(
      onTap: () => _toggleCategory(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? baseColor : baseColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.black26,
            width: isSelected ? 4 : 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: baseColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
              : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  category.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: isSelected
                        ? [const Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)]
                        : [],
                  ),
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: Colors.white, size: 24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final canConfirm = _selectedCategoryIds.length == 5;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "SELECIONADAS: ${_selectedCategoryIds.length} / 5",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: canConfirm ? _confirmSelection : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700), // Gold
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text(
              "CONFIRMAR E CRIAR SALA",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
