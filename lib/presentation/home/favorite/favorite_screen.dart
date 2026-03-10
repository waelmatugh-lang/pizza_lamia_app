import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/pizza_model.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../details/pizza_details_screen.dart';
import 'cubit/favorite_cubit.dart';
import 'cubit/favorite_state.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  late Future<List<Map<String, dynamic>>> _pizzasFuture;

  @override
  void initState() {
    super.initState();
    _loadPizzas();
  }

  void _loadPizzas() {
    setState(() {
      _pizzasFuture = Supabase.instance.client.from('pizzas').select();
    });
  }

  Future<void> _handleRefresh() async {
    _loadPizzas();
    await _pizzasFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFFF5722),
        child: BlocBuilder<FavoriteCubit, FavoriteState>(
          builder: (context, favoriteState) {
            if (favoriteState.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5722)),
              );
            }

            if (favoriteState.favoritePizzaIds.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No favorites yet 💔',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _pizzasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null || data.isEmpty) {
                  return const Center(child: Text('No items found.'));
                }

                final allItems = data
                    .map((e) => PizzaModel.fromJson(e))
                    .toList();

                final favoriteItems = allItems.where((item) {
                  final pizzaId = int.tryParse(item.id) ?? 0;
                  return favoriteState.favoritePizzaIds.contains(pizzaId);
                }).toList();

                if (favoriteItems.isEmpty) {
                  // Fallback in case there are IDs but no matching pizzas
                  return const Center(child: Text('No favorites found.'));
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  itemCount: favoriteItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildPizzaCard(context, favoriteItems[index]);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPizzaCard(BuildContext context, PizzaModel pizza) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => PizzaDetailsScreen(pizza: pizza),
        );
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722),
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pizza.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${pizza.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<CartCubit, CartState>(
                        builder: (context, state) {
                          final count = state.items
                              .where((i) => i.pizza.id == pizza.id)
                              .fold<int>(0, (sum, item) => sum + item.quantity);

                          if (count == 0) {
                            return ElevatedButton(
                              onPressed: () {
                                context.read<CartCubit>().addToCart(pizza);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFFF5722),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Icon(Icons.add, size: 20),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    count == 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    color: const Color(0xFFFF5722),
                                    size: 20,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    context.read<CartCubit>().removeFromCart(
                                      pizza,
                                    );
                                  },
                                ),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Color(0xFFFF5722),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Color(0xFFFF5722),
                                    size: 20,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    context.read<CartCubit>().addToCart(pizza);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: ClipOval(
                      child: Image.network(
                        pizza.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: BlocBuilder<FavoriteCubit, FavoriteState>(
              builder: (context, state) {
                final pizzaId = int.tryParse(pizza.id) ?? 0;
                final isFavorite = state.favoritePizzaIds.contains(pizzaId);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    context.read<FavoriteCubit>().toggleFavorite(pizzaId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
