import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/pizza_model.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late Future<List<PizzaModel>> _pizzasFuture;

  @override
  void initState() {
    super.initState();
    _loadPizzas();
  }

  void _loadPizzas() {
    setState(() {
      _pizzasFuture = Supabase.instance.client
          .from('pizzas')
          .select()
          .then((data) => data.map((e) => PizzaModel.fromJson(e)).toList());
    });
  }

  Future<void> _updateAvailability(
    PizzaModel pizza,
    bool isAvailable, {
    String? availableAtString,
  }) async {
    try {
      await Supabase.instance.client
          .from('pizzas')
          .update({
            'is_available': isAvailable,
            'available_at': availableAtString,
          })
          .eq('id', pizza.id);

      _loadPizzas(); // Refresh UI locally
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAvailabilityDialog(PizzaModel pizza) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('متى سيتوفر الصنف؟'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final targetTime = DateTime.now().toUtc().add(
                    const Duration(minutes: 15),
                  );
                  _updateAvailability(
                    pizza,
                    false,
                    availableAtString: targetTime.toIso8601String(),
                  );
                },
                child: const Text('بعد 15 دقيقة'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final targetTime = DateTime.now().toUtc().add(
                    const Duration(minutes: 30),
                  );
                  _updateAvailability(
                    pizza,
                    false,
                    availableAtString: targetTime.toIso8601String(),
                  );
                },
                child: const Text('بعد 30 دقيقة'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final targetTime = DateTime.now().toUtc().add(
                    const Duration(hours: 1),
                  );
                  _updateAvailability(
                    pizza,
                    false,
                    availableAtString: targetTime.toIso8601String(),
                  );
                },
                child: const Text('بعد ساعة'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateAvailability(
                    pizza,
                    false,
                    availableAtString: null, // Indefinitely unavailable
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('غير متاح حالياً'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنيو'),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<PizzaModel>>(
        future: _pizzasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          final pizzas = snapshot.data;
          if (pizzas == null || pizzas.isEmpty) {
            return const Center(child: Text('لا توجد أصناف في المنيو.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pizzas.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final pizza = pizzas[index];
              return ListTile(
                leading: ClipOval(
                  child: Image.network(
                    pizza.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.fastfood,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
                title: Text(
                  pizza.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('\$${pizza.price.toStringAsFixed(2)}'),
                trailing: Switch(
                  value: pizza.isAvailable,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    if (value) {
                      // Turn ON: Available immediately
                      _updateAvailability(pizza, true, availableAtString: null);
                    } else {
                      // Turn OFF: Show dialog for time selection
                      _showAvailabilityDialog(pizza);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
