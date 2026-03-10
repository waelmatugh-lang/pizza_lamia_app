import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/admin_orders_cubit.dart';
import 'cubit/admin_orders_state.dart';
import 'admin_menu_screen.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminOrdersCubit(),
      child: const _AdminOrdersView(),
    );
  }
}

class _AdminOrdersView extends StatelessWidget {
  const _AdminOrdersView();

  String _translateText(String text) {
    switch (text) {
      case 'Pending':
        return 'قيد الانتظار';
      case 'Preparing':
        return 'جاري التحضير';
      case 'Completed':
      case 'Delivered':
        return 'مكتمل';
      case 'Delivery':
        return 'توصيل';
      case 'Pickup':
        return 'استلام';
      case 'Cancelled':
        return 'ملغى';
      default:
        return text;
    }
  }

  String _translateCustomizations(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('Add:', 'إضافة:')
        .replaceAll('Remove:', 'إزالة:')
        .replaceAll('Extra Cheese', 'جبنة إضافية')
        .replaceAll('Harissa', 'هريسة')
        .replaceAll('No Olives', 'بدون زيتون')
        .replaceAll('Olives', 'زيتون');
  }

  void _showSettingsDialog(BuildContext context) {
    final cubit = context.read<AdminOrdersCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: cubit,
          child: const _AudioSettingsDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة تحكم الإدارة - الطلبات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.fastfood),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminMenuScreen(),
                ),
              );
            },
            tooltip: 'إدارة المنيو',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'إعدادات الصوت',
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
        builder: (context, state) {
          if (state is AdminOrdersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5722)),
            );
          }
          if (state is AdminOrdersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AdminOrdersCubit>().initRealtimeOrders();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'إعادة الاتصال بالرادار... 🔄',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is AdminOrdersLoaded) {
            final orders = state.orders;
            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد طلبات حالياً',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            // Sort orders to put 'Completed' and 'Delivered' and 'Cancelled' at the bottom
            final List<Map<String, dynamic>> sortedOrders = List.from(orders);
            sortedOrders.sort((a, b) {
              final statusA = a['status'] ?? '';
              final statusB = b['status'] ?? '';

              final isCompletedA =
                  statusA == 'Completed' ||
                  statusA == 'Delivered' ||
                  statusA.toLowerCase().contains('cancelled') ||
                  statusA == 'مكتمل' ||
                  statusA == 'ملغى';
              final isCompletedB =
                  statusB == 'Completed' ||
                  statusB == 'Delivered' ||
                  statusB.toLowerCase().contains('cancelled') ||
                  statusB == 'مكتمل' ||
                  statusB == 'ملغى';

              if (isCompletedA && !isCompletedB) return 1;
              if (!isCompletedA && isCompletedB) return -1;

              // If both are same category, sort by date (newest first)
              final dateA =
                  DateTime.tryParse(a['created_at'].toString()) ??
                  DateTime.now();
              final dateB =
                  DateTime.tryParse(b['created_at'].toString()) ??
                  DateTime.now();
              return dateB.compareTo(dateA);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedOrders.length,
              itemBuilder: (context, index) {
                final order = sortedOrders[index];
                final isCompletedOrder =
                    order['status'] == 'Completed' ||
                    order['status'] == 'Delivered' ||
                    (order['status'] as String? ?? '').toLowerCase().contains(
                      'cancelled',
                    ) ||
                    order['status'] == 'مكتمل' ||
                    order['status'] == 'ملغى';

                return Opacity(
                  opacity: isCompletedOrder
                      ? 0.6
                      : 1.0, // Fade out completed/cancelled orders
                  child: _buildOrderCard(context, order),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final status = order['status'] ?? 'غير معروف';
    final orderType = order['order_type'] ?? 'Delivery';
    final createdAtStr = order['created_at'] as String?;

    // Financials
    final double totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final double deliveryFee =
        (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final double subtotal = totalPrice - deliveryFee;

    // CRM / Customer Info — المصدر الأول هو customer_name المحفوظ مباشرةً في جدول orders
    String customerName = order['customer_name']?.toString().trim() ?? '';
    if (customerName.isEmpty) {
      // Fallback: محاولة قراءة من profiles (إن وُجد JOIN مستقبلاً)
      final Map<String, dynamic> profile =
          order['profiles'] as Map<String, dynamic>? ?? {};
      final String fName = profile['first_name']?.toString().trim() ?? '';
      final String lName = profile['last_name']?.toString().trim() ?? '';
      customerName = '$fName $lName'.trim();
    }
    if (customerName.isEmpty) customerName = 'زبون';
    final String customerPhone = order['customer_phone'] ?? 'غير مسجل';
    final String customerEmail = order['customer_email'] ?? 'غير مسجل';
    final String customerAddress = order['customer_address'] ?? 'غير مسجل';
    final bool isVip = order['is_vip'] == true;
    final bool isNewCustomer = order['is_new_customer'] == true;

    DateTime? createdAt;
    if (createdAtStr != null) {
      createdAt = DateTime.tryParse(createdAtStr)?.toLocal();
    }

    final timeString = createdAt != null
        ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : 'غير محدد';

    final itemsList = order['items'] as List<dynamic>? ?? [];

    Color statusColor = Colors.grey;
    if (status == 'Pending' || status == 'قيد الانتظار') {
      statusColor = Colors.orange;
    } else if (status == 'Preparing') {
      statusColor = Colors.blue;
    } else if (status == 'Completed' || status == 'Delivered') {
      statusColor = Colors.green;
    } else if (status.toLowerCase().contains('cancelled') || status == 'ملغى') {
      statusColor = Colors.red;
    }

    Widget badge;
    if (isVip) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'VIP 🌟',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (isNewCustomer) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'زبون جديد 🆕',
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'زبون عادي 👤',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Order # & Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلب #$orderId',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeString,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Text(
                    _translateText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // 2. Customer CRM Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                badge,
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'الهاتف:', customerPhone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, 'الإيميل:', customerEmail),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'العنوان:', customerAddress),

            const Divider(height: 30),

            // 3. Items List
            const Text(
              'عناصر الطلب:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: itemsList.map((item) {
                  if (item is Map<String, dynamic>) {
                    final name =
                        item['name'] ??
                        item['product_name'] ??
                        'منتج غير معروف';
                    final qty = item['quantity']?.toString() ?? '1';
                    final maxCustoms = item['customizations'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$name x$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (maxCustoms.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _translateCustomizations(maxCustoms),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),

            const Divider(height: 30),

            // 4. Financials & Type
            _buildInfoRow(
              Icons.delivery_dining,
              'نوع الطلب:',
              _translateText(orderType),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.receipt_long,
              'الطلب (بدون توصيل):',
              '\$${subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.local_shipping,
              'رسوم التوصيل:',
              '\$${deliveryFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.monetization_on, size: 20, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'الإجمالي الكلي:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),

            // 5. Action Buttons (Full Order Lifecycle)
            const Divider(),
            const SizedBox(height: 10),
            _buildActionButtons(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'سبب الرفض',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('الكمية غير متوفرة'),
              onTap: () {
                context.read<AdminOrdersCubit>().updateOrderStatus(
                  orderId,
                  'Cancelled: الكمية غير متوفرة',
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('خارج نطاق التوصيل'),
              onTap: () {
                context.read<AdminOrdersCubit>().updateOrderStatus(
                  orderId,
                  'Cancelled: خارج نطاق التوصيل',
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('المطعم مغلق حالياً'),
              onTap: () {
                context.read<AdminOrdersCubit>().updateOrderStatus(
                  orderId,
                  'Cancelled: المطعم مغلق حالياً',
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('لا يمكننا تلبية الطلب حالياً'),
              onTap: () {
                context.read<AdminOrdersCubit>().updateOrderStatus(
                  orderId,
                  'Cancelled: لا يمكننا تلبية الطلب حالياً',
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> order) {
    final String currentStatus = (order['status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final String orderType = (order['order_type'] ?? 'delivery')
        .toString()
        .toLowerCase()
        .trim();
    final String orderId = order['id'].toString();

    if (currentStatus == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => context.read<AdminOrdersCubit>().updateOrderStatus(
              orderId,
              'Preparing',
            ),
            child: const Text(
              'قبول وتحضير',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _showRejectDialog(context, orderId),
            child: const Text(
              'رفض الطلب',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    if (currentStatus == 'preparing') {
      if (orderType == 'delivery') {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 45),
          ),
          onPressed: () => context.read<AdminOrdersCubit>().updateOrderStatus(
            orderId,
            'Delivering',
          ),
          child: const Text(
            'إرسال للتوصيل 🛵',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      } else {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 45),
          ),
          onPressed: () => context.read<AdminOrdersCubit>().updateOrderStatus(
            orderId,
            'Ready',
          ),
          child: const Text(
            'الطلب جاهز للاستلام 🍕',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      }
    }

    if (currentStatus == 'delivering') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          minimumSize: const Size(double.infinity, 45),
        ),
        onPressed: () => context.read<AdminOrdersCubit>().updateOrderStatus(
          orderId,
          'Completed',
        ),
        child: const Text(
          'تم التسليم ✔️',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    if (currentStatus == 'ready') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          minimumSize: const Size(double.infinity, 45),
        ),
        onPressed: () => context.read<AdminOrdersCubit>().updateOrderStatus(
          orderId,
          'Completed',
        ),
        child: const Text(
          'تم الاستلام ✔️',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _AudioSettingsDialog extends StatefulWidget {
  const _AudioSettingsDialog();

  @override
  State<_AudioSettingsDialog> createState() => _AudioSettingsDialogState();
}

class _AudioSettingsDialogState extends State<_AudioSettingsDialog> {
  final List<Map<String, String>> _audioOptions = [
    {'name': 'صوت 1 (abc)', 'file': 'abc.mp3'},
    {'name': 'صوت 2 (abcd)', 'file': 'abcd.mp3'},
    {'name': 'صوت 3 (adme)', 'file': 'adme.mp3'},
    {'name': 'تنبيه (alert)', 'file': 'alert.mp3'},
    {'name': 'جرس (bell)', 'file': 'bell.mp3'},
    {'name': 'صوت 4 (bobo)', 'file': 'bobo.mp3'},
    {'name': 'رنين (chime)', 'file': 'chime.mp3'},
    {'name': 'صوت 5 (coco)', 'file': 'coco.mp3'},
    {'name': 'رنين كلاسيكي (ding)', 'file': 'ding.mp3'},
    {'name': 'صوت 6 (dody)', 'file': 'dody.mp3'},
    {'name': 'إشعار (notification)', 'file': 'notification.mp3'},
    {'name': 'إنذار (siren)', 'file': 'siren.mp3'},
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminOrdersCubit>();
    return AlertDialog(
      title: const Text('إعدادات صوت التنبيه'),
      content: DropdownButtonFormField<String>(
        initialValue: cubit.selectedAudioFile,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        items: _audioOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option['file'],
            child: Text(option['name']!),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            cubit.setSelectedAudio(newValue);
            setState(() {});
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'إغلاق',
            style: TextStyle(color: Color(0xFFFF5722)),
          ),
        ),
      ],
    );
  }
}
