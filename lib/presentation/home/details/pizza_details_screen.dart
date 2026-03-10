import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/pizza_model.dart';
import '../../cart/cubit/cart_cubit.dart';

class PizzaDetailsScreen extends StatefulWidget {
  final PizzaModel pizza;

  const PizzaDetailsScreen({super.key, required this.pizza});

  @override
  State<PizzaDetailsScreen> createState() => _PizzaDetailsScreenState();
}

class _PizzaDetailsScreenState extends State<PizzaDetailsScreen> {
  int _quantity = 1;

  final List<String> _addOns = ['جبنة إضافية', 'هريسة', 'ثوم', 'فطر', 'زيتون'];
  final List<String> _removals = [
    'بدون زيتون',
    'بدون بصل',
    'بدون فلفل حلو',
    'بدون طماطم',
  ];

  final Set<String> _selectedAddOns = {};
  final Set<String> _selectedRemovals = {};

  String _buildCustomizationsString() {
    final List<String> parts = [];
    if (_selectedAddOns.isNotEmpty) {
      parts.add('إضافة: ${_selectedAddOns.join('، ')}');
    }
    if (_selectedRemovals.isNotEmpty) {
      parts.add('إزالة: ${_selectedRemovals.join('، ')}');
    }
    return parts.join(' | ');
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('التفاصيل'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Pizza Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: ClipOval(
                child: Image.network(
                  widget.pizza.imageUrl,
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

          // Details Bottom Sheet
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFDF6E3), // from app theme
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.pizza.name,
                          style: Theme.of(context).textTheme.displayMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${(widget.pizza.price * _quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pizza.description.isNotEmpty
                                ? widget.pizza.description
                                : 'منتج لذيذ وطازج بمكونات عالية الجودة.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 24),

                          // Customizations Section
                          if (widget.pizza.category.trim().toLowerCase() !=
                                  'drinks' &&
                              widget.pizza.category.trim().toLowerCase() !=
                                  'drink' &&
                              widget.pizza.category.trim() != 'مشروبات') ...[
                            const Text(
                              'إضافات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              children: _addOns.map((addon) {
                                final isSelected = _selectedAddOns.contains(
                                  addon,
                                );
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(addon),
                                  selectedColor: const Color(
                                    0xFFFF5722,
                                  ).withValues(alpha: 0.2),
                                  checkmarkColor: const Color(0xFFFF5722),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedAddOns.add(addon);
                                      } else {
                                        _selectedAddOns.remove(addon);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              'إزالة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              children: _removals.map((removal) {
                                final isSelected = _selectedRemovals.contains(
                                  removal,
                                );
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(removal),
                                  selectedColor: Colors.red.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: Colors.red,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedRemovals.add(removal);
                                      } else {
                                        _selectedRemovals.remove(removal);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar (Quantity & Add to Cart)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove,
                                color: Color(0xFFFF5722),
                              ),
                              onPressed: _decrementQuantity,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFFFF5722),
                              ),
                              onPressed: _incrementQuantity,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: widget.pizza.isCurrentlyAvailable
                                ? () {
                                    final customizationsString =
                                        _buildCustomizationsString();

                                    for (int i = 0; i < _quantity; i++) {
                                      context.read<CartCubit>().addToCart(
                                        widget.pizza,
                                        customizations: customizationsString,
                                      );
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تمت إضافة ${_quantity}x ${widget.pizza.name} للسلة!',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.pizza.isCurrentlyAvailable
                                  ? const Color(0xFFFF5722)
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              widget.pizza.isCurrentlyAvailable
                                  ? 'إضافة للسلة'
                                  : 'نفذت الكمية',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
