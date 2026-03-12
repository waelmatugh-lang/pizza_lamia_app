import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/location_service.dart';
import 'cubit/address_cubit.dart';
import 'cubit/address_state.dart';

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({super.key});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchLocationAutomatically();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// يجلب الموقع الحالي تلقائياً ويملأ حقل العنوان
  Future<void> _fetchLocationAutomatically() async {
    setState(() {
      _isFetchingLocation = true;
      _addressController.text = 'جارٍ تحديد موقعك...';
    });

    final position = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (position == null) {
      setState(() {
        _isFetchingLocation = false;
        _addressController.text = '';
      });
      return;
    }

    final address = await LocationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    if (!mounted) return;

    setState(() {
      _isFetchingLocation = false;
      _lat = position.latitude;
      _lng = position.longitude;
      _addressController.text = address ?? '';
    });
  }

  void _handleSave(BuildContext context) {
    final title = _titleController.text.trim();
    final addressText = _addressController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم الموقع (مثال: المنزل)'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (addressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال تفاصيل العنوان'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    context.read<AddressCubit>().saveAddress(
      title: title,
      addressText: addressText,
      lat: _lat ?? 0.0,
      lng: _lng ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressCubit, AddressState>(
      listener: (context, state) {
        if (state is AddressSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم حفظ العنوان بنجاح!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
        if (state is AddressError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isSaving = state is AddressLoading;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              'إضافة عنوان جديد',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بطاقة معلومات الموقع التلقائي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF5722,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gps_fixed,
                          color: Color(0xFFFF5722),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تحديد الموقع تلقائياً',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isFetchingLocation
                                  ? 'جارٍ تحديد موقعك عبر GPS...'
                                  : (_lat != null
                                        ? 'تم تحديد الموقع ✅'
                                        : 'لم يتم تحديد الموقع'),
                              style: TextStyle(
                                color: _lat != null
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isFetchingLocation)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF5722),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _fetchLocationAutomatically,
                          child: const Text(
                            'إعادة التحديد',
                            style: TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // حقل اسم الموقع
                const Text(
                  'اسم الموقع',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _titleController,
                  hint: 'مثال: المنزل، العمل، منزل الأهل...',
                  icon: Icons.label_outline,
                ),

                const SizedBox(height: 20),

                // حقل تفاصيل العنوان
                const Text(
                  'تفاصيل العنوان',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _addressController,
                  hint: 'الشارع، الحي، أقرب معلم...',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  enabled: !_isFetchingLocation,
                ),

                const SizedBox(height: 8),
                Text(
                  'يمكنك تعديل نص العنوان يدوياً إذا أردت.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),

                const SizedBox(height: 40),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : () => _handleSave(context),
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_alt),
                    label: Text(
                      isSaving ? 'جارٍ الحفظ...' : 'حفظ العنوان',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFFFF5722,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.grey)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Icon(icon, color: Colors.grey),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
