import 'package:equatable/equatable.dart';

abstract class AdminOrdersState extends Equatable {
  const AdminOrdersState();

  @override
  List<Object?> get props => [];
}

class AdminOrdersLoading extends AdminOrdersState {}

class AdminOrdersLoaded extends AdminOrdersState {
  final List<Map<String, dynamic>> orders;

  const AdminOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class AdminOrdersError extends AdminOrdersState {
  final String message;

  const AdminOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}
