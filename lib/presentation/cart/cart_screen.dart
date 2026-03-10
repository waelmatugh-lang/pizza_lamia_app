import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/cart_cubit.dart';
import 'cubit/cart_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isDelivery = true; // Default to Delivery
  final double _deliveryFee = 5.00;
  bool _isLoading = false;

  String _translateCustomizations(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('Add:', 'إضافة:')
        .replaceAll('Remove:', 'إزالة:')
        .replaceAll('Extra Cheese', 'جبنة إضافية')
        .replaceAll('Harissa', 'هريسة')
        .replaceAll('No Olives', 'بدون زيتون')
        .replaceAll('Olives', 'زيتون');
  }

  Future<void> _handleCheckout(BuildContext context, CartState state) async {
    setState(() {
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await context.read<CartCubit>().checkout(
        orderType: _isDelivery ? 'Delivery' : 'Pickup',
        deliveryFee: _isDelivery ? _deliveryFee : 0.0,
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الطلب بنجاح! 🍕'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(); // Go back to Home Screen
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الطلب: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلتي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'سلتك فارغة',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: state.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final cartItem = state.items[index];
              final pizza = cartItem.pizza;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipOval(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        pizza.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.local_pizza,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(
                    '${pizza.name} x${cartItem.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cartItem.customizations.isNotEmpty)
                        Text(
                          _translateCustomizations(cartItem.customizations),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        '\$${cartItem.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFF5722),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      context.read<CartCubit>().removeCartItem(cartItem);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إزالة ${pizza.name} من السلة!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('توصيل'),
                        icon: Icon(Icons.two_wheeler),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('استلام من المطعم'),
                        icon: Icon(Icons.storefront),
                      ),
                    ],
                    selected: {_isDelivery},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isDelivery = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFFF5722).withValues(alpha: 0.1);
                        }
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFFF5722);
                        }
                        return Colors.grey;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isDelivery) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'رسوم التوصيل:',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          '\$${_deliveryFee.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإجمالي:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${(state.totalPrice + (_isDelivery ? _deliveryFee : 0.0)).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleCheckout(context, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'إتمام الطلب (\$${(state.totalPrice + (_isDelivery ? _deliveryFee : 0.0)).toStringAsFixed(2)})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
