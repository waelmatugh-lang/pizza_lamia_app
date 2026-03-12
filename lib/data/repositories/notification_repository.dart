import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final _client = Supabase.instance.client;

  /// جلب إشعارات المستخدم مرتبة تنازلياً
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// تحديث حالة الإشعار إلى مقروء
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// إرسال إشعار جديد لمستخدم محدد
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
