import 'package:equatable/equatable.dart';
import '../../../../data/models/cart_item_model.dart';

class CartState extends Equatable {
  final List<CartItem> items;

  const CartState({required this.items});

  double get totalPrice {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  List<Object?> get props => [items];
}
