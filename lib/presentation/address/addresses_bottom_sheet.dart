import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/address_cubit.dart';
import 'cubit/address_state.dart';
import 'add_new_address_screen.dart';
import 'edit_address_screen.dart';
import '../../core/cubit/delivery_location_cubit.dart';

class AddressesBottomSheet extends StatelessWidget {
  const AddressesBottomSheet({super.key});

  /// يفتح الـ BottomSheet مع حقن AddressCubit وجلب البيانات تلقائياً
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (context) => AddressCubit()..loadAddresses(),
        child: const AddressesBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFFF5722),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'عناوين التوصيل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // قائمة العناوين
              Expanded(
                child: BlocBuilder<AddressCubit, AddressState>(
                  builder: (context, state) {
                    if (state is AddressLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF5722),
                        ),
                      );
                    }

                    if (state is AddressError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is AddressSuccess) {
                      if (state.addresses.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_off,
                                color: Colors.grey,
                                size: 56,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد عناوين محفوظة',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'أضف عنوانك لتسريع الطلبات القادمة',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: state.addresses.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final address = state.addresses[index];
                          final title = address['title'] as String? ?? 'عنوان';
                          final addressText =
                              address['address_text'] as String? ?? '';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF5722,
                                ).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.place,
                                color: Color(0xFFFF5722),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              addressText,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // --- زر التعديل ---
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blueAccent,
                                    size: 20,
                                  ),
                                  tooltip: 'تعديل',
                                  onPressed: () async {
                                    final cubit = context.read<AddressCubit>();
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: cubit,
                                          child: EditAddressScreen(
                                            id: address['id'].toString(),
                                            initialTitle: title,
                                            initialAddressText: addressText,
                                          ),
                                        ),
                                      ),
                                    );
                                    if (context.mounted) cubit.loadAddresses();
                                  },
                                ),
                                // --- زر الحذف ---
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  tooltip: 'حذف',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('تأكيد الحذف'),
                                        content: Text(
                                          'هل أنت متأكد من حذف عنوان "$title"؟ لا يمكن التراجع عن هذا الإجراء.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, false),
                                            child: const Text('إلغاء'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, true),
                                            child: const Text('حذف'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if ((confirmed ?? false) &&
                                        context.mounted) {
                                      context
                                          .read<AddressCubit>()
                                          .removeAddress(
                                            address['id'].toString(),
                                          );
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // تحديث الحالة العامة للتوصيل بالعنوان المختار
                              final lat = (address['latitude'] as num?)
                                  ?.toDouble();
                              final lng = (address['longitude'] as num?)
                                  ?.toDouble();
                              if (lat != null && lng != null) {
                                context
                                    .read<DeliveryLocationCubit>()
                                    .selectSavedAddress(
                                      lat: lat,
                                      lng: lng,
                                      addressText: addressText,
                                    );
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),

              // زر "إضافة عنوان جديد"
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final cubit = context.read<AddressCubit>();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: cubit,
                            child: const AddNewAddressScreen(),
                          ),
                        ),
                      );
                      // إعادة جلب القائمة بعد العودة من شاشة الإضافة
                      if (context.mounted) cubit.loadAddresses();
                    },
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text(
                      'إضافة عنوان جديد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
