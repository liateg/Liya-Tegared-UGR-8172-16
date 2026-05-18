import 'package:equatable/equatable.dart';
import '../models/recipe_model.dart';

abstract class RecipeEvent extends Equatable {
  const RecipeEvent();

  @override
  List<Object?> get props => [];
}

// 1. Fetch all recipes
class LoadRecipesEvent extends RecipeEvent {
  const LoadRecipesEvent();
}

// 2. Search recipes with a query
class SearchRecipesEvent extends RecipeEvent {
  final String query;

  const SearchRecipesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

// 3. Create a recipe
class CreateRecipeEvent extends RecipeEvent {
  final Recipe recipe;

  const CreateRecipeEvent(this.recipe);

  @override
  List<Object?> get props => [recipe];
}

// 4. Update a recipe
class UpdateRecipeEvent extends RecipeEvent {
  final Recipe recipe;

  const UpdateRecipeEvent(this.recipe);

  @override
  List<Object?> get props => [recipe];
}

// 5. Delete a recipe
class DeleteRecipeEvent extends RecipeEvent {
  final int recipeId;

  const DeleteRecipeEvent(this.recipeId);

  @override
  List<Object?> get props => [recipeId];
}

// 6. Toggle favorite status of a recipe
class ToggleFavoriteEvent extends RecipeEvent {
  final Recipe recipe;

  const ToggleFavoriteEvent(this.recipe);

  @override
  List<Object?> get props => [recipe];
}

// 7. Get random recipe (Surprise Me)
class GetRandomRecipeEvent extends RecipeEvent {
  const GetRandomRecipeEvent();
}

// 8. Filter recipes by cuisine type
class FilterCuisineEvent extends RecipeEvent {
  final String cuisine;

  const FilterCuisineEvent(this.cuisine);

  @override
  List<Object?> get props => [cuisine];
}
