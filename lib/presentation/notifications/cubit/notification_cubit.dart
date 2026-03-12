import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  NotificationCubit({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository(),
      super(const NotificationInitial());

  /// يُشغّل Realtime Stream لإشعارات المستخدم — يُستدعى مرة واحدة عند بدء التطبيق.
  void listenToNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      emit(const NotificationError('المستخدم غير مسجل الدخول'));
      return;
    }

    emit(const NotificationLoading());
    _subscription?.cancel();

    _subscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            final unreadCount = data.where((n) => n['is_read'] == false).length;
            emit(
              NotificationSuccess(
                notifications: List<Map<String, dynamic>>.from(data),
                unreadCount: unreadCount,
              ),
            );
          },
          onError: (_) {
            emit(const NotificationError('انقطع الاتصال. أعد فتح التطبيق.'));
          },
          cancelOnError: false,
        );
  }

  /// تحديث إشعار كـ مقروء محلياً وفي Supabase
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      // الـ Stream سيُحدّث الـ State تلقائياً بعد تحديث Supabase
    } catch (_) {}
  }

  /// للاستخدام الداخلي من AdminOrdersCubit: إرسال إشعار لزبون
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await _repository.sendNotification(
        userId: userId,
        title: title,
        body: body,
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
