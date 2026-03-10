import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_orders_state.dart';

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isFirstLoad = true;
  final Set<String> _knownOrderIds = {};

  String _selectedAudioFile = 'ding.mp3';
  String get selectedAudioFile => _selectedAudioFile;

  AdminOrdersCubit() : super(AdminOrdersLoading()) {
    _loadAudioPreference().then((_) {
      initRealtimeOrders();
    });
  }

  Future<void> _loadAudioPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedAudioFile = prefs.getString('admin_audio_file') ?? 'ding.mp3';
  }

  Future<void> setSelectedAudio(String fileName) async {
    _selectedAudioFile = fileName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_audio_file', fileName);
    // Play preview once
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.play(AssetSource('audio/$fileName'));
  }

  void initRealtimeOrders() {
    // Prevent overlapping subscriptions
    _ordersSubscription?.cancel();
    emit(AdminOrdersLoading());
    _isFirstLoad = true;
    _knownOrderIds.clear();

    _ordersSubscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            if (_isFirstLoad) {
              _isFirstLoad = false;
              for (var order in data) {
                _knownOrderIds.add(order['id'].toString());
              }
            } else {
              bool hasNewPendingOrder = false;
              for (var order in data) {
                final orderId = order['id'].toString();
                if (!_knownOrderIds.contains(orderId)) {
                  _knownOrderIds.add(orderId);
                  final status = (order['status'] ?? '')
                      .toString()
                      .toLowerCase();
                  if (status == 'pending' || status == 'قيد الانتظار') {
                    hasNewPendingOrder = true;
                  }
                }
              }
              if (hasNewPendingOrder) {
                // Loop the notification for real incoming orders
                _audioPlayer.setReleaseMode(ReleaseMode.loop);
                _audioPlayer.play(AssetSource('audio/$_selectedAudioFile'));
              }
            }
            emit(AdminOrdersLoaded(data));
          },
          onError: (error) {
            emit(AdminOrdersError('انقطع الاتصال بالخادم. قم بتحديث الصفحة.'));
          },
          cancelOnError: false, // Don't crash on errors like code 1006
        );
  }

  void stopSound() {
    _audioPlayer.stop();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    stopSound(); // Fix 1: Stop alarm immediately
    try {
      // Fix 2: Optimistic Local Update (Prevent row vanishing)
      if (state is AdminOrdersLoaded) {
        final currentOrders = (state as AdminOrdersLoaded).orders;
        final updatedOrders = currentOrders.map((order) {
          if (order['id'].toString() == orderId) {
            return {...order, 'status': newStatus};
          }
          return order;
        }).toList();
        emit(AdminOrdersLoaded(updatedOrders));
      }

      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      // Ignored: real-time stream handles reflection
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    stopSound(); // Fix 1: Stop alarm immediately
    try {
      // Fix 2: Optimistic Local Update
      if (state is AdminOrdersLoaded) {
        final currentOrders = (state as AdminOrdersLoaded).orders;
        final updatedOrders = currentOrders.map((order) {
          if (order['id'].toString() == orderId) {
            return {
              ...order,
              'status': 'Cancelled',
              'rejection_reason': reason,
            };
          }
          return order;
        }).toList();
        emit(AdminOrdersLoaded(updatedOrders));
      }

      await _supabase
          .from('orders')
          .update({'status': 'Cancelled', 'rejection_reason': reason})
          .eq('id', orderId);
    } catch (e) {
      // Ignored: real-time stream handles reflection
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
