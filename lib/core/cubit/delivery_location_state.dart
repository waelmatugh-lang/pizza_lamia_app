import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryLocationState extends Equatable {
  /// الموقع الفعلي للجهاز (GPS)
  final Position? actualDevicePosition;

  /// الموقع المختار للتوصيل (قد يختلف عن الفعلي مستقبلاً)
  final Position? selectedDeliveryPosition;

  /// العنوان النصي للموقع المختار
  final String deliveryAddressText;

  /// تنبيه إذا اختلف موقع التوصيل عن الموقع الحالي بأكثر من 500م
  final bool showDistanceWarning;

  /// حالة التحميل أثناء جلب الإحداثيات أو العنوان
  final bool isLoading;

  const DeliveryLocationState({
    this.actualDevicePosition,
    this.selectedDeliveryPosition,
    this.deliveryAddressText = 'جاري التحديد...',
    this.showDistanceWarning = false,
    this.isLoading = false,
  });

  DeliveryLocationState copyWith({
    Position? actualDevicePosition,
    Position? selectedDeliveryPosition,
    String? deliveryAddressText,
    bool? showDistanceWarning,
    bool? isLoading,
  }) {
    return DeliveryLocationState(
      actualDevicePosition: actualDevicePosition ?? this.actualDevicePosition,
      selectedDeliveryPosition:
          selectedDeliveryPosition ?? this.selectedDeliveryPosition,
      deliveryAddressText: deliveryAddressText ?? this.deliveryAddressText,
      showDistanceWarning: showDistanceWarning ?? this.showDistanceWarning,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    actualDevicePosition?.latitude,
    actualDevicePosition?.longitude,
    selectedDeliveryPosition?.latitude,
    selectedDeliveryPosition?.longitude,
    deliveryAddressText,
    showDistanceWarning,
    isLoading,
  ];
}
