import 'dart:math';
import '../models/recipe_model.dart';
import '../services/api_service.dart';

class RecipeRepository {
  final ApiService apiService;
  final List<Recipe> _localRecipes = [];

  RecipeRepository({required this.apiService});

  // Fetch all recipes from API, or return cached ones if already loaded
  Future<List<Recipe>> fetchRecipes() async {
    if (_localRecipes.isNotEmpty) {
      return List.unmodifiable(_localRecipes);
    }

    try {
      final response = await apiService.get('recipes');
      final data = response.data;
      
      if (data != null && data['recipes'] != null) {
        final List<dynamic> list = data['recipes'];
        final recipes = list.map((json) => Recipe.fromJson(json)).toList();
        
        _localRecipes.clear();
        _localRecipes.addAll(recipes);
      }
      
      return List.unmodifiable(_localRecipes);
    } catch (e) {
      rethrow;
    }
  }

  // Search recipes
  Future<List<Recipe>> searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      return fetchRecipes();
    }

    try {
      // 1. Fetch from server
      final response = await apiService.get('recipes/search', queryParameters: {'q': query});
      final data = response.data;
      List<Recipe> serverResults = [];

      if (data != null && data['recipes'] != null) {
        final List<dynamic> list = data['recipes'];
        serverResults = list.map((json) => Recipe.fromJson(json)).toList();
      }

      // 2. Query locally created/modified recipes to make sure custom items matching the search query show up!
      final localCustomMatching = _localRecipes.where((recipe) {
        // Only include locally added (id >= 100) or modified recipes that match the query
        final matchesQuery = recipe.name.toLowerCase().contains(query.toLowerCase()) ||
            recipe.cuisine.toLowerCase().contains(query.toLowerCase()) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        
        return recipe.id >= 100 && matchesQuery;
      }).toList();

      // Combine server results and custom local results
      final combined = [...localCustomMatching, ...serverResults];
      
      // Remove any server results that are already overridden in our _localRecipes cache (e.g. edited)
      final finalResults = <Recipe>[];
      for (var recipe in combined) {
        final cached = _localRecipes.firstWhere(
          (r) => r.id == recipe.id,
          orElse: () => recipe,
        );
        if (!finalResults.any((r) => r.id == cached.id)) {
          finalResults.add(cached);
        }
      }

      return finalResults;
    } catch (e) {
      // Fallback: if server fails or internet goes offline, search inside local cache
      return _localRecipes.where((recipe) {
        return recipe.name.toLowerCase().contains(query.toLowerCase()) ||
            recipe.cuisine.toLowerCase().contains(query.toLowerCase()) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    }
  }

  // Get a random recipe for the "Surprise Me" feature
  Future<Recipe> getRandomRecipe() async {
    try {
      final response = await apiService.get('recipes/random');
      final data = response.data;
      
      if (data != null) {
        // Sometimes random returns a list or a single object.
        // In DummyJSON, random returns a list of one recipe, e.g. { "id": 1, ... } or { "recipes": [ { ... } ] }
        if (data is Map && data.containsKey('recipes')) {
          final List<dynamic> list = data['recipes'];
          if (list.isNotEmpty) {
            return Recipe.fromJson(list.first);
          }
        }
        return Recipe.fromJson(data);
      }
      throw 'Failed to parse random recipe.';
    } catch (e) {
      // Fallback: return a random recipe from local cache if available
      if (_localRecipes.isNotEmpty) {
        final random = Random();
        return _localRecipes[random.nextInt(_localRecipes.length)];
      }
      rethrow;
    }
  }

  // Create (Post) Recipe
  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      // Convert to JSON (excluding ID, which DummyJSON creates, or including a mock user ID)
      final body = recipe.toJson();
      body.remove('id'); // let dummyjson mock the creation
      if (body['userId'] == null || body['userId'] == 0) {
        body['userId'] = 1; // dummyjson requires userId
      }

      // Hit DummyJSON POST endpoint
      await apiService.post('recipes/add', data: body);
      
      // DummyJSON returns the added recipe with an ID. We will construct our local recipe.
      // Generate a truly unique local ID for local persistence integrity (e.g. 100+)
      final nextId = _localRecipes.isEmpty 
          ? 100 
          : (_localRecipes.map((r) => r.id).reduce(max) + 1);
      final newId = nextId < 100 ? 100 : nextId;

      final newRecipe = recipe.copyWith(
        id: newId,
        rating: 5.0,
        reviewCount: 0,
      );

      // Prepend to our local cache so it appears first
      _localRecipes.insert(0, newRecipe);
      return newRecipe;
    } catch (e) {
      // Fallback: If network fails, add to local cache anyway for offline capability
      final nextId = _localRecipes.isEmpty 
          ? 100 
          : (_localRecipes.map((r) => r.id).reduce(max) + 1);
      final newId = nextId < 100 ? 100 : nextId;
      final newRecipe = recipe.copyWith(id: newId);
      _localRecipes.insert(0, newRecipe);
      return newRecipe;
    }
  }

  // Update (Put) Recipe
  Future<Recipe> updateRecipe(Recipe recipe) async {
    try {
      // If the recipe was created locally (id >= 100), the backend server doesn't know about it.
      // In this case, we SKIP the network request and update directly in the local cache to avoid 404!
      if (recipe.id < 100) {
        final body = recipe.toJson();
        // Hit DummyJSON PUT endpoint
        await apiService.put('recipes/${recipe.id}', data: body);
      }

      // Update in our in-memory cache
      final index = _localRecipes.indexWhere((r) => r.id == recipe.id);
      if (index != -index) {
        _localRecipes[index] = recipe;
      } else {
        _localRecipes.add(recipe);
      }

      return recipe;
    } catch (e) {
      // Fallback: Update locally if network fails
      final index = _localRecipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _localRecipes[index] = recipe;
      }
      return recipe;
    }
  }

  // Delete Recipe
  Future<void> deleteRecipe(int id) async {
    try {
      // If the recipe is a server recipe (id < 100), hit delete endpoint.
      if (id < 100) {
        await apiService.delete('recipes/$id');
      }

      // Remove from our in-memory cache
      _localRecipes.removeWhere((r) => r.id == id);
    } catch (e) {
      // Fallback: Delete locally even if network fails
      _localRecipes.removeWhere((r) => r.id == id);
    }
  }
}
