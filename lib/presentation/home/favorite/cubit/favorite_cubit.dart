import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'favorite_state.dart';

class FavoriteCubit extends Cubit<FavoriteState> {
  FavoriteCubit() : super(const FavoriteState()) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      emit(state.copyWith(isLoading: true));
      final response = await Supabase.instance.client
          .from('favorites')
          .select('pizza_id')
          .eq('user_id', user.id);

      final List<int> favorites = (response as List)
          .map((item) => int.parse(item['pizza_id'].toString()))
          .toList();

      emit(
        state.copyWith(
          favoritePizzaIds: favorites,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(error: 'Failed to load favorites: $e', isLoading: false),
      );
    }
  }

  Future<void> toggleFavorite(int pizzaId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(state.copyWith(error: 'User not logged in'));
      return;
    }

    final isFavorite = state.favoritePizzaIds.contains(pizzaId);

    // Optimistic UI update
    final newFavorites = List<int>.from(state.favoritePizzaIds);
    if (isFavorite) {
      newFavorites.remove(pizzaId);
    } else {
      newFavorites.add(pizzaId);
    }
    emit(state.copyWith(favoritePizzaIds: newFavorites, error: null));

    try {
      if (isFavorite) {
        // Remove from favorites
        await Supabase.instance.client.from('favorites').delete().match({
          'user_id': user.id,
          'pizza_id': pizzaId,
        });
      } else {
        // Add to favorites
        await Supabase.instance.client.from('favorites').insert({
          'user_id': user.id,
          'pizza_id': pizzaId,
        });
      }
    } catch (e) {
      // Revert on failure
      final revertedFavorites = List<int>.from(state.favoritePizzaIds);
      if (isFavorite) {
        revertedFavorites.add(pizzaId);
      } else {
        revertedFavorites.remove(pizzaId);
      }
      emit(
        state.copyWith(
          favoritePizzaIds: revertedFavorites,
          error: 'Failed to update favorite: $e',
        ),
      );
    }
  }
}
