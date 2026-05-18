import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'recipe_event.dart';
import 'recipe_state.dart';
import '../repositories/recipe_repository.dart';

class RecipeBloc extends Bloc<RecipeEvent, RecipeState> {
  final RecipeRepository recipeRepository;

  RecipeBloc({required this.recipeRepository}) : super(const RecipeInitial()) {
    on<LoadRecipesEvent>(_onLoadRecipes);
    on<SearchRecipesEvent>(_onSearchRecipes);
    on<CreateRecipeEvent>(_onCreateRecipe);
    on<UpdateRecipeEvent>(_onUpdateRecipe);
    on<DeleteRecipeEvent>(_onDeleteRecipe);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<GetRandomRecipeEvent>(_onGetRandomRecipe);
    on<FilterCuisineEvent>(_onFilterCuisine);
  }

  // 1. Load Recipes Event Handler
  Future<void> _onLoadRecipes(LoadRecipesEvent event, Emitter<RecipeState> emit) async {
    // Keep favorites if transitioning from loaded
    final currentFavorites = state is RecipeLoaded 
        ? (state as RecipeLoaded).favoriteIds 
        : <int>{};
    
    emit(const RecipeLoading());
    try {
      final recipes = await recipeRepository.fetchRecipes();
      emit(RecipeLoaded(
        recipes: recipes,
        favoriteIds: currentFavorites,
      ));
    } catch (e) {
      emit(RecipeError(e.toString()));
    }
  }

  // 2. Search Recipes Event Handler
  Future<void> _onSearchRecipes(SearchRecipesEvent event, Emitter<RecipeState> emit) async {
    final currentFavorites = state is RecipeLoaded 
        ? (state as RecipeLoaded).favoriteIds 
        : <int>{};
    final currentCuisine = state is RecipeLoaded 
        ? (state as RecipeLoaded).selectedCuisine 
        : 'All';

    emit(const RecipeLoading());
    try {
      final results = await recipeRepository.searchRecipes(event.query);
      emit(RecipeLoaded(
        recipes: results,
        favoriteIds: currentFavorites,
        searchQuery: event.query,
        selectedCuisine: currentCuisine,
      ));
    } catch (e) {
      emit(RecipeError(e.toString()));
    }
  }

  // 3. Create Recipe Event Handler
  Future<void> _onCreateRecipe(CreateRecipeEvent event, Emitter<RecipeState> emit) async {
    if (state is RecipeLoaded) {
      final loadedState = state as RecipeLoaded;
      emit(const RecipeLoading());
      try {
        await recipeRepository.createRecipe(event.recipe);
        final updatedRecipes = await recipeRepository.fetchRecipes();
        emit(RecipeLoaded(
          recipes: updatedRecipes,
          favoriteIds: loadedState.favoriteIds,
          selectedCuisine: 'All', // Reset cuisine filter to show the new recipe at top
          searchQuery: '',
          successMessage: 'Recipe "${event.recipe.name}" created successfully!',
        ));
      } catch (e) {
        emit(RecipeError(e.toString()));
      }
    }
  }

  // 4. Update Recipe Event Handler
  Future<void> _onUpdateRecipe(UpdateRecipeEvent event, Emitter<RecipeState> emit) async {
    if (state is RecipeLoaded) {
      final loadedState = state as RecipeLoaded;
      emit(const RecipeLoading());
      try {
        await recipeRepository.updateRecipe(event.recipe);
        final updatedRecipes = await recipeRepository.fetchRecipes();
        emit(RecipeLoaded(
          recipes: updatedRecipes,
          favoriteIds: loadedState.favoriteIds,
          selectedCuisine: loadedState.selectedCuisine,
          searchQuery: loadedState.searchQuery,
          successMessage: 'Recipe "${event.recipe.name}" updated successfully!',
        ));
      } catch (e) {
        emit(RecipeError(e.toString()));
      }
    }
  }

  // 5. Delete Recipe Event Handler
  Future<void> _onDeleteRecipe(DeleteRecipeEvent event, Emitter<RecipeState> emit) async {
    if (state is RecipeLoaded) {
      final loadedState = state as RecipeLoaded;
      emit(const RecipeLoading());
      try {
        await recipeRepository.deleteRecipe(event.recipeId);
        final updatedRecipes = await recipeRepository.fetchRecipes();
        emit(RecipeLoaded(
          recipes: updatedRecipes,
          favoriteIds: loadedState.favoriteIds,
          selectedCuisine: loadedState.selectedCuisine,
          searchQuery: loadedState.searchQuery,
          successMessage: 'Recipe deleted successfully!',
        ));
      } catch (e) {
        emit(RecipeError(e.toString()));
      }
    }
  }

  // 6. Toggle Favorite Event Handler
  Future<void> _onToggleFavorite(ToggleFavoriteEvent event, Emitter<RecipeState> emit) async {
    if (state is RecipeLoaded) {
      final loadedState = state as RecipeLoaded;
      final updatedFavorites = Set<int>.from(loadedState.favoriteIds);
      
      if (updatedFavorites.contains(event.recipe.id)) {
        updatedFavorites.remove(event.recipe.id);
      } else {
        updatedFavorites.add(event.recipe.id);
      }
      
      emit(loadedState.copyWith(
        favoriteIds: updatedFavorites,
        successMessage: () => null, // ensure success message is not repeated
      ));
    }
  }

  // 7. Surprise Me Event Handler (Get Random Recipe)
  Future<void> _onGetRandomRecipe(GetRandomRecipeEvent event, Emitter<RecipeState> emit) async {
    if (state is RecipeLoaded) {
      final loadedState = state as RecipeLoaded;
      emit(const RecipeLoading());
      try {
        final randomRecipe = await recipeRepository.getRandomRecipe();
        // Return back to loaded state with randomRecipe payload set
        final currentRecipes = await recipeRepository.fetchRecipes();
        emit(RecipeLoaded(
          recipes: currentRecipes,
          favoriteIds: loadedState.favoriteIds,
          selectedCuisine: loadedState.selectedCuisine,
          searchQuery: loadedState.searchQuery,
          randomRecipe: randomRecipe,
        ));
      } catch (e) {
        emit(RecipeError(e.toString()));
      }
    }
  }

  // 8. Filter Cuisine Event Handler
  Future<void> _onFilterCuisine(FilterCuisineEvent event, Emitter<RecipeState> emit) async {
    if (state is RecipeLoaded) {
      final loadedState = state as RecipeLoaded;
      emit(const RecipeLoading());
      try {
        final allRecipes = await recipeRepository.fetchRecipes();
        final filtered = event.cuisine == 'All'
            ? allRecipes
            : allRecipes.where((recipe) {
                final matchCuisine = recipe.cuisine.toLowerCase() == event.cuisine.toLowerCase();
                final matchTag = recipe.tags.any((tag) => tag.toLowerCase() == event.cuisine.toLowerCase());
                return matchCuisine || matchTag;
              }).toList();

        emit(RecipeLoaded(
          recipes: filtered,
          favoriteIds: loadedState.favoriteIds,
          selectedCuisine: event.cuisine,
          searchQuery: '', // Reset search query when switching tags/cuisines
        ));
      } catch (e) {
        emit(RecipeError(e.toString()));
      }
    }
  }
}
