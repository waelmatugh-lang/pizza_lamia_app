import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/pizza_model.dart';
import 'favorite/cubit/favorite_cubit.dart';
import 'favorite/cubit/favorite_state.dart';
import 'favorite/favorite_screen.dart';
import '../cart/cubit/cart_cubit.dart';
import '../cart/cubit/cart_state.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart'; // Ensure correct import
import '../profile/profile_screen.dart'; // Ensure correct import
import 'details/pizza_details_screen.dart';
import '../admin/admin_orders_screen.dart';
import '../../core/cubit/delivery_location_cubit.dart';
import '../../core/cubit/delivery_location_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeContent(),
    OrdersScreen(),
    FavoriteScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      extendBody: true, // Important for the curved overlapping effect
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildFloatingCartBar(), _buildCurvedNavigationBar()],
      ),
    );
  }

  Widget _buildFloatingCartBar() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${state.items.fold<int>(0, (sum, i) => sum + i.quantity)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Text(
                  'عرض السلة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${state.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurvedNavigationBar() {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: const Color(0xFFFF5722),
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'الطلبات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                label: 'المفضلة',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'الحساب',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _selectedCategoryIndex = 0;
  late Future<List<Map<String, dynamic>>> _pizzasFuture;

  @override
  void initState() {
    super.initState();
    _loadPizzas();
    // تشغيل تحديد الموقع تلقائياً عند فتح الشاشة الرئيسية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DeliveryLocationCubit>().initDefaultLocation();
      }
    });
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: BlocBuilder<DeliveryLocationCubit, DeliveryLocationState>(
          builder: (context, locState) {
            return InkWell(
              onTap: () {
                /* تغيير الموقع — مستقبلاً */
              },
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التوصيل إلى:',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (locState.isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF5722),
                          ),
                        )
                      else
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF5722),
                          size: 16,
                        ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locState.isLoading
                              ? 'جاري التحديد...'
                              : locState.deliveryAddressText,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black54,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Color(0xFFFF5722)),
            onPressed: () {
              final TextEditingController passwordController =
                  TextEditingController();
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.lock, color: Color(0xFFFF5722)),
                        SizedBox(width: 8),
                        Text(
                          'صلاحية الإدارة 🔒',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    content: TextField(
                      controller: passwordController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'أدخل الرمز السري',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (passwordController.text == '0000') {
                            Navigator.pop(dialogContext); // Close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminOrdersScreen(),
                              ),
                            );
                          } else {
                            Navigator.pop(dialogContext); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('الرمز السري غير صحيح!'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('دخول'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFFF5722),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== شريط تنبيه المسافة =====
              BlocBuilder<DeliveryLocationCubit, DeliveryLocationState>(
                builder: (context, locState) {
                  if (!locState.showDistanceWarning) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'تنبيه: موقع التوصيل المختار يختلف عن موقعك الحالي',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // ==============================
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildCategories(),
              const SizedBox(height: 24),
              _buildPizzasList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث عن بيتزا...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['الاكثر طلباً', 'ميني بيتزا', 'مطبقة', 'مشروبات'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = index == _selectedCategoryIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF5722)
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPizzasList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pizzasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Error fetching items: ${snapshot.error}');
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
          return const Center(child: Text('لا توجد عناصر.'));
        }

        final allItems = data.map((e) => PizzaModel.fromJson(e)).toList();
        final filteredItems = allItems.where((item) {
          final cat = item.category.trim().toLowerCase();
          final name = item.name.toLowerCase();

          if (_selectedCategoryIndex == 0) {
            return item.isBestSeller;
          } else if (_selectedCategoryIndex == 1) {
            return name.contains('ميني');
          } else if (_selectedCategoryIndex == 2) {
            return name.contains('مطبقة');
          } else {
            return cat == 'drinks' || cat == 'drink' || cat == 'مشروبات';
          }
        }).toList();

        if (filteredItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Center(
              child: Text(
                'لا توجد عناصر',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildPizzaCard(context, filteredItems[index]);
          },
        );
      },
    );
  }

  Widget _buildPizzaCard(BuildContext context, PizzaModel pizza) {
    Color cardColor;
    if (!pizza.isCurrentlyAvailable) {
      cardColor = Colors.grey[600] ?? Colors.grey;
    } else if (_selectedCategoryIndex == 0) {
      cardColor = Colors.amber[700] ?? Colors.amber;
    } else if (_selectedCategoryIndex == 1) {
      cardColor = Colors.red[600] ?? Colors.red;
    } else if (_selectedCategoryIndex == 2) {
      cardColor = Colors.deepOrange[600] ?? Colors.deepOrange;
    } else {
      cardColor = Colors.blue[600] ?? Colors.blue;
    }

    return GestureDetector(
      onTap: pizza.isCurrentlyAvailable
          ? () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => PizzaDetailsScreen(pizza: pizza),
              );
            }
          : null,
      child: Opacity(
        opacity: pizza.isCurrentlyAvailable ? 1.0 : 0.5,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
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
                            if (!pizza.isCurrentlyAvailable) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'غير متوفر',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }

                            final count = state.items
                                .where((i) => i.pizza.id == pizza.id)
                                .fold<int>(
                                  0,
                                  (sum, item) => sum + item.quantity,
                                );

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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                                      context.read<CartCubit>().addToCart(
                                        pizza,
                                      );
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
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
                        if (!pizza.isCurrentlyAvailable)
                          Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              color: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 24,
                              ),
                              child: const Text(
                                'غير متاح',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!pizza.isCurrentlyAvailable && pizza.availableAt != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (_) => DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    final targetTime = pizza.availableAt!.toLocal();
                    final now = DateTime.now();
                    final difference = targetTime.difference(now);

                    if (difference.isNegative || difference.inSeconds <= 0) {
                      // Note: In an ideal architecture, this state change should be driven by
                      // a state manager or database listener. For purely UI-driven temporary fix:
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() {});
                      });
                      return const SizedBox.shrink();
                    }

                    String twoDigits(int n) => n.toString().padLeft(2, '0');
                    String hours = difference.inHours > 0
                        ? '${difference.inHours}:'
                        : '';
                    String minutes = twoDigits(
                      difference.inMinutes.remainder(60),
                    );
                    String seconds = twoDigits(
                      difference.inSeconds.remainder(60),
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'يتوفر خلال: $hours$minutes:$seconds ⏳',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
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
      ),
    );
  }
}
