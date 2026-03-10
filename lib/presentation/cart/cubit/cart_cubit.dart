import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/pizza_model.dart';
import '../../../../data/models/cart_item_model.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState(items: []));

  void addToCart(PizzaModel pizza, {String customizations = ''}) {
    final itemKey = '${pizza.id}_$customizations';
    final existingIndex = state.items.indexWhere((item) => item.id == itemKey);

    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state.items);
      final existingItem = updatedList[existingIndex];
      updatedList[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      emit(CartState(items: List.from(updatedList)));
    } else {
      final newItem = CartItem(
        pizza: pizza,
        customizations: customizations,
        quantity: 1,
      );
      final updatedList = List<CartItem>.from(state.items)..add(newItem);
      emit(CartState(items: List.from(updatedList)));
    }
  }

  void removeFromCart(PizzaModel pizza, {String customizations = ''}) {
    final itemKey = '${pizza.id}_$customizations';
    final existingIndex = state.items.indexWhere((item) => item.id == itemKey);

    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state.items);
      final existingItem = updatedList[existingIndex];
      if (existingItem.quantity > 1) {
        updatedList[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        );
      } else {
        updatedList.removeAt(existingIndex);
      }
      emit(CartState(items: List.from(updatedList)));
    } else {
      final anyMatchIndex = state.items.indexWhere(
        (item) => item.pizza.id == pizza.id,
      );
      if (anyMatchIndex >= 0) {
        final updatedList = List<CartItem>.from(state.items);
        final existingItem = updatedList[anyMatchIndex];
        if (existingItem.quantity > 1) {
          updatedList[anyMatchIndex] = existingItem.copyWith(
            quantity: existingItem.quantity - 1,
          );
        } else {
          updatedList.removeAt(anyMatchIndex);
        }
        emit(CartState(items: List.from(updatedList)));
      }
    }
  }

  void removeCartItem(CartItem item) {
    final updatedList = List<CartItem>.from(state.items)..remove(item);
    emit(CartState(items: List.from(updatedList)));
  }

  void clearCart() {
    emit(const CartState(items: []));
  }

  Future<void> checkout({
    required String orderType,
    required double deliveryFee,
  }) async {
    if (state.items.isEmpty) return;

    final totalPrice = state.totalPrice + deliveryFee;
    final itemsJson = state.items
        .map(
          (item) => {
            'name': item.pizza.name,
            'quantity': item.quantity,
            'price': item.pizza.price,
            if (item.customizations.isNotEmpty)
              'customizations': item.customizations,
          },
        )
        .toList();

    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id;

    // القيم الافتراضية قبل جلب الـ profile
    String customerName = 'زبون';
    String customerPhone = currentUser?.phone ?? 'غير مسجل';
    String customerEmail = currentUser?.email ?? 'غير مسجل';
    String customerAddress = 'غير مسجل';

    // --- الخطوة 1: جلب بيانات الـ profile بشكل مستقل ---
    if (userId != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('first_name, last_name, phone, email, address')
            .eq('id', userId)
            .maybeSingle(); // maybeSingle لا يـ throw إذا لم يُوجد سجل

        if (profile != null) {
          final String fName = profile['first_name']?.toString().trim() ?? '';
          final String lName = profile['last_name']?.toString().trim() ?? '';
          customerName = fName.isNotEmpty
              ? '$fName $lName'.trim()
              : customerName;

          final String profilePhone = profile['phone']?.toString().trim() ?? '';
          customerPhone = profilePhone.isNotEmpty
              ? profilePhone
              : customerPhone;

          final String profileEmail = profile['email']?.toString().trim() ?? '';
          customerEmail = profileEmail.isNotEmpty
              ? profileEmail
              : customerEmail;

          customerAddress =
              profile['address']?.toString().trim().isNotEmpty == true
              ? profile['address'].toString().trim()
              : 'غير مسجل';
        }
      } catch (_) {
        // إذا فشل جلب الـ profile، نكمل بالقيم الافتراضية من الـ auth
      }
    }

    // --- الخطوة 2: تجهيز بيانات الطلب وإرساله ---
    try {
      final Map<String, dynamic> orderData = {
        'user_id': userId,
        'order_type': orderType,
        'total_price': totalPrice,
        'delivery_fee': deliveryFee,
        'items': itemsJson,
        'status': 'Pending',
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_email': customerEmail,
        'customer_address': customerAddress,
      };

      await Supabase.instance.client.from('orders').insert(orderData);
      clearCart();
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }
}
