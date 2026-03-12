import 'package:supabase_flutter/supabase_flutter.dart';

class AddressRepository {
  final _client = Supabase.instance.client;

  /// جلب جميع عناوين المستخدم من جدول user_addresses
  Future<List<Map<String, dynamic>>> getUserAddresses(String userId) async {
    final response = await _client
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// حفظ عنوان جديد في جدول user_addresses
  Future<void> saveAddress({
    required String userId,
    required String title,
    required String addressText,
    required double lat,
    required double lng,
  }) async {
    await _client.from('user_addresses').insert({
      'user_id': userId,
      'title': title,
      'address_text': addressText,
      'latitude': lat,
      'longitude': lng,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// تعديل بيانات عنوان موجود
  Future<void> updateAddress(
    String id,
    String title,
    String addressText,
  ) async {
    await _client
        .from('user_addresses')
        .update({'title': title, 'address_text': addressText})
        .eq('id', id);
  }

  /// حذف عنوان بـ id محدد
  Future<void> deleteAddress(String id) async {
    await _client.from('user_addresses').delete().eq('id', id);
  }
}
