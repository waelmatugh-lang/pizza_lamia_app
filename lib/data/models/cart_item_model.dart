import 'package:equatable/equatable.dart';
import 'pizza_model.dart';

class CartItem extends Equatable {
  final PizzaModel pizza;
  final String customizations;
  final int quantity;

  const CartItem({
    required this.pizza,
    this.customizations = '',
    this.quantity = 1,
  });

  String get id => '${pizza.id}_$customizations';

  double get totalPrice => pizza.price * quantity;

  CartItem copyWith({
    PizzaModel? pizza,
    String? customizations,
    int? quantity,
  }) {
    return CartItem(
      pizza: pizza ?? this.pizza,
      customizations: customizations ?? this.customizations,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      pizza: PizzaModel.fromJson(json['pizza'] as Map<String, dynamic>),
      customizations: json['customizations'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pizza': pizza.toJson(),
      'customizations': customizations,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }

  @override
  List<Object?> get props => [pizza, customizations, quantity];
}
