class FavoriteState {
  final List<int> favoritePizzaIds;
  final bool isLoading;
  final String? error;

  const FavoriteState({
    this.favoritePizzaIds = const [],
    this.isLoading = false,
    this.error,
  });

  FavoriteState copyWith({
    List<int>? favoritePizzaIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoriteState(
      favoritePizzaIds: favoritePizzaIds ?? this.favoritePizzaIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
