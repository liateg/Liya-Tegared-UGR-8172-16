import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/recipe_card.dart';
import '../bloc/recipe_bloc.dart';
import '../bloc/recipe_event.dart';
import '../bloc/recipe_state.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final List<String> _cuisines = ['All', 'Italian', 'Mexican', 'Asian', 'American'];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<RecipeBloc>().add(SearchRecipesEvent(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Explorer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<RecipeBloc, RecipeState>(
          builder: (context, state) {
            String activeCuisine = 'All';
            if (state is RecipeLoaded) {
              activeCuisine = state.selectedCuisine;
            }

            return Column(
              children: [
                // 1. Search Bar Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by title, tags, or cuisine...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<RecipeBloc>().add(const SearchRecipesEvent(''));
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // 2. Filter Category Chips
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cuisines.length,
                    itemBuilder: (context, i) {
                      final cuisine = _cuisines[i];
                      final isSelected = activeCuisine == cuisine;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cuisine),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              context.read<RecipeBloc>().add(FilterCuisineEvent(cuisine));
                              _searchController.clear(); // Clear search bar for clarity
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Main Results Display
                Expanded(
                  child: _buildExplorerContent(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExplorerContent(BuildContext context, RecipeState state) {
    if (state is RecipeLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is RecipeError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.read<RecipeBloc>().add(const LoadRecipesEvent());
                },
                child: const Text('Reload Recipes'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is RecipeLoaded) {
      final recipes = state.recipes;
      if (recipes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No recipes found matching your criteria.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching for something else or changing the active tag chip.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: recipes.length,
        itemBuilder: (context, i) {
          final recipe = recipes[i];
          final isFav = state.favoriteIds.contains(recipe.id);
          
          return RecipeCard(
            recipe: recipe,
            isFavorite: isFav,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipe: recipe),
                ),
              );
            },
          );
        },
      );
    }

    return const SizedBox();
  }
}
