import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/recipe_model.dart';
import '../bloc/recipe_bloc.dart';
import '../bloc/recipe_event.dart';
import '../bloc/recipe_state.dart';

class AddEditRecipeScreen extends StatefulWidget {
  final Recipe? recipeToEdit;

  const AddEditRecipeScreen({super.key, this.recipeToEdit});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _imageController;
  late final TextEditingController _cookTimeController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _instructionsController;
  
  String _cuisine = 'Italian';
  String _difficulty = 'Easy';
  final List<String> _cuisines = ['All', 'Italian', 'Mexican', 'Asian', 'American'];
  
  bool get isEditMode => widget.recipeToEdit != null;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.recipeToEdit?.name ?? '');
    _imageController = TextEditingController(text: widget.recipeToEdit?.image ?? '');
    _cookTimeController = TextEditingController(
      text: widget.recipeToEdit != null ? widget.recipeToEdit!.cookTimeMinutes.toString() : '',
    );
    
    // Join ingredients and instructions by line breaks for text field display
    _ingredientsController = TextEditingController(
      text: widget.recipeToEdit?.ingredients.join('\n') ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.recipeToEdit?.instructions.join('\n') ?? '',
    );
    
    if (isEditMode) {
      _cuisine = widget.recipeToEdit!.cuisine;
      _difficulty = widget.recipeToEdit!.difficulty;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _cookTimeController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onSaveRecipe(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final String image = _imageController.text.trim();
    final int cookTime = int.tryParse(_cookTimeController.text.trim()) ?? 15;
    
    // Split text fields by line breaks to recover list of items
    final List<String> ingredients = _ingredientsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
        
    final List<String> instructions = _instructionsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (isEditMode) {
      // 1. Dispatch update event
      final updatedRecipe = widget.recipeToEdit!.copyWith(
        name: name,
        image: image,
        cookTimeMinutes: cookTime,
        cuisine: _cuisine,
        difficulty: _difficulty,
        ingredients: ingredients,
        instructions: instructions,
      );
      context.read<RecipeBloc>().add(UpdateRecipeEvent(updatedRecipe));
    } else {
      // 2. Construct a new Recipe and dispatch creation event
      final newRecipe = Recipe(
        id: 0, // Placeholder, Repository will assign a unique ID
        name: name,
        image: image,
        cookTimeMinutes: cookTime,
        prepTimeMinutes: 10, // Default value
        servings: 4, // Default value
        difficulty: _difficulty,
        cuisine: _cuisine,
        caloriesPerServing: 300, // Default value
        tags: [_cuisine],
        userId: 1, // Default user
        rating: 5.0,
        reviewCount: 0,
        mealType: const ['Dinner'],
        ingredients: ingredients,
        instructions: instructions,
      );
      context.read<RecipeBloc>().add(CreateRecipeEvent(newRecipe));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Recipe' : 'Create New Recipe'),
        leading: isEditMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // In non-edit mode, if it's the tab screen, don't pop, just clear
                  _formKey.currentState?.reset();
                  _nameController.clear();
                  _imageController.clear();
                  _cookTimeController.clear();
                  _ingredientsController.clear();
                  _instructionsController.clear();
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form cleared')),
                  );
                },
              ),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<RecipeBloc, RecipeState>(
          listener: (context, state) {
            if (state is RecipeLoaded && state.successMessage != null) {
              // Successfully saved!
              if (isEditMode) {
                // Return to detail screen
                Navigator.pop(context);
              } else {
                // If in main tab shell, clear form and show success message
                _nameController.clear();
                _imageController.clear();
                _cookTimeController.clear();
                _ingredientsController.clear();
                _instructionsController.clear();
                FocusScope.of(context).unfocus();
              }
            }
          },
          builder: (context, state) {
            final isLoading = state is RecipeLoading;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditMode
                            ? 'Update this recipe\'s details and ingredients.'
                            : 'Share your culinary masterpiece with the world.',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      // Recipe Name
                      _buildTextFormField(
                        label: 'Recipe Name',
                        hint: 'e.g. Summer Truffle Pasta',
                        controller: _nameController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a recipe name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Image URL Input & Live Preview Card
                      _buildTextFormField(
                        label: 'Cover Image URL',
                        hint: 'https://example.com/image.jpg',
                        controller: _imageController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter an image URL';
                          }
                          if (!val.startsWith('http')) {
                            return 'Please enter a valid URL (starting with http/https)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Live Image Preview Widget
                      ValueListenableBuilder(
                        valueListenable: _imageController,
                        builder: (context, value, child) {
                          final url = value.text.trim();
                          if (url.startsWith('http')) {
                            return Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Text('Invalid image URL or unable to load preview', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Row for Cuisine and Difficulty
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Cuisine Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _cuisines.contains(_cuisine) ? _cuisine : 'Italian',
                                      items: _cuisines
                                          .where((c) => c != 'All')
                                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (val) => setState(() => _cuisine = val ?? 'Italian'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Difficulty Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _difficulty,
                                      items: const [
                                        DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                                        DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                                      ],
                                      onChanged: (val) => setState(() => _difficulty = val ?? 'Easy'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cooking Time
                      _buildTextFormField(
                        label: 'Cooking Time (Minutes)',
                        hint: 'e.g. 25',
                        controller: _cookTimeController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter cooking time';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ingredients (Multi-line)
                      const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _ingredientsController,
                          maxLines: 4,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter at least one ingredient';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter one ingredient per line...\n200g Fresh Pasta\n2 tbsp Olive Oil',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Instructions (Multi-line)
                      const Text('Instructions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _instructionsController,
                          maxLines: 4,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter at least one instruction step';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter one step per line...\nBoil salted water...\nSauté the garlic...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _onSaveRecipe(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isEditMode ? 'Update Recipe' : 'Save Recipe',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
