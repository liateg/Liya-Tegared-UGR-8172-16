import 'package:equatable/equatable.dart';
import '../models/recipe_model.dart';

abstract class RecipeState extends Equatable {
  const RecipeState();

  @override
  List<Object?> get props => [];
}

// 1. Initial State
class RecipeInitial extends RecipeState {
  const RecipeInitial();
}

// 2. Loading State (used during initialization or heavy requests)
class RecipeLoading extends RecipeState {
  const RecipeLoading();
}

// 3. Loaded State (holds all stateful fields)
class RecipeLoaded extends RecipeState {
  final List<Recipe> recipes; // All current recipes matching filters/searches
  final Set<int> favoriteIds; // Unique IDs of favorite recipes
  final String selectedCuisine; // Active cuisine chip filter ('All', 'Italian', etc.)
  final String searchQuery; // Active search query
  final Recipe? randomRecipe; // Set briefly to navigate when "Surprise Me" is triggered
  final String? successMessage; // Set briefly to trigger a toast/snack bar on CRUD completion

  const RecipeLoaded({
    required this.recipes,
    required this.favoriteIds,
    this.selectedCuisine = 'All',
    this.searchQuery = '',
    this.randomRecipe,
    this.successMessage,
  });

  RecipeLoaded copyWith({
    List<Recipe>? recipes,
    Set<int>? favoriteIds,
    String? selectedCuisine,
    String? searchQuery,
    Recipe? Function()? randomRecipe, // Wrap in function to support resetting back to null
    String? Function()? successMessage,
  }) {
    return RecipeLoaded(
      recipes: recipes ?? this.recipes,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      selectedCuisine: selectedCuisine ?? this.selectedCuisine,
      searchQuery: searchQuery ?? this.searchQuery,
      randomRecipe: randomRecipe != null ? randomRecipe() : this.randomRecipe,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        recipes,
        favoriteIds,
        selectedCuisine,
        searchQuery,
        randomRecipe,
        successMessage,
      ];
}

// 4. Error State
class RecipeError extends RecipeState {
  final String message;

  const RecipeError(this.message);

  @override
  List<Object?> get props => [message];
}
