import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'delivery_location_state.dart';

class DeliveryLocationCubit extends Cubit<DeliveryLocationState> {
  static const double _warningDistanceMeters = 500.0;

  DeliveryLocationCubit() : super(const DeliveryLocationState());

  /// يُشغَّل عند بدء التطبيق — يجلب موقع GPS ويعينه كموقع توصيل افتراضي.
  Future<void> initDefaultLocation() async {
    // لا تعيد الجلب إذا كان الموقع محدداً مسبقاً
    if (state.actualDevicePosition != null) return;

    emit(
      state.copyWith(isLoading: true, deliveryAddressText: 'جاري التحديد...'),
    );

    final Position? position = await LocationService.getCurrentLocation();

    if (position == null) {
      emit(
        state.copyWith(
          isLoading: false,
          deliveryAddressText: 'تعذّر تحديد الموقع',
        ),
      );
      return;
    }

    final String? address = await LocationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    emit(
      state.copyWith(
        isLoading: false,
        actualDevicePosition: position,
        selectedDeliveryPosition: position,
        deliveryAddressText: address ?? 'موقعك الحالي',
        showDistanceWarning: false,
      ),
    );
  }

  /// يُستدعى إذا اختار المستخدم موقع توصيل مختلفاً (للاستخدام المستقبلي).
  Future<void> changeDeliveryLocation(Position newPosition) async {
    emit(state.copyWith(isLoading: true));

    final String? address = await LocationService.getAddressFromLatLng(
      newPosition.latitude,
      newPosition.longitude,
    );

    bool distanceWarning = false;
    if (state.actualDevicePosition != null) {
      final double distanceInMeters = LocationService.distanceBetween(
        state.actualDevicePosition!.latitude,
        state.actualDevicePosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      distanceWarning = distanceInMeters > _warningDistanceMeters;
    }

    emit(
      state.copyWith(
        isLoading: false,
        selectedDeliveryPosition: newPosition,
        deliveryAddressText: address ?? 'الموقع المختار',
        showDistanceWarning: distanceWarning,
      ),
    );
  }
}
