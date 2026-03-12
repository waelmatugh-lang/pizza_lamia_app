import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/address_repository.dart';
import 'address_state.dart';

class AddressCubit extends Cubit<AddressState> {
  final AddressRepository _repository;

  AddressCubit({AddressRepository? repository})
    : _repository = repository ?? AddressRepository(),
      super(const AddressInitial());

  /// جلب عناوين المستخدم الحالي من Supabase
  Future<void> loadAddresses() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      emit(const AddressError('المستخدم غير مسجل الدخول'));
      return;
    }

    emit(const AddressLoading());
    try {
      final addresses = await _repository.getUserAddresses(userId);
      emit(AddressSuccess(addresses));
    } catch (e) {
      emit(AddressError('فشل جلب العناوين: $e'));
    }
  }

  /// حفظ عنوان جديد ثم إعادة جلب القائمة
  Future<void> saveAddress({
    required String title,
    required String addressText,
    required double lat,
    required double lng,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    emit(const AddressLoading());
    try {
      await _repository.saveAddress(
        userId: userId,
        title: title,
        addressText: addressText,
        lat: lat,
        lng: lng,
      );
      await loadAddresses(); // تحديث القائمة بعد الحفظ
    } catch (e) {
      emit(AddressError('فشل حفظ العنوان: $e'));
    }
  }

  /// تعديل عنوان موجود ثم تحديث القائمة
  Future<void> editAddress({
    required String id,
    required String title,
    required String addressText,
  }) async {
    emit(const AddressLoading());
    try {
      await _repository.updateAddress(id, title, addressText);
      await loadAddresses();
    } catch (e) {
      emit(AddressError('فشل تعديل العنوان: $e'));
    }
  }

  /// حذف عنوان ثم تحديث القائمة
  Future<void> removeAddress(String id) async {
    emit(const AddressLoading());
    try {
      await _repository.deleteAddress(id);
      await loadAddresses();
    } catch (e) {
      emit(AddressError('فشل حذف العنوان: $e'));
    }
  }
}
