import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Stream<List<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _ordersStream = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
    } else {
      _ordersStream = const Stream.empty();
    }
  }

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

  String _getLocalizedStatus(String? status) {
    if (status == null) return 'غير معروف';
    final s = status.toLowerCase().trim();
    if (s.contains('pending')) return 'قيد الانتظار';
    if (s.contains('preparing')) return 'جاري التحضير';
    if (s.contains('delivering')) return 'جاري التوصيل 🛵';
    if (s.contains('ready')) return 'جاهز للاستلام 🍕';
    if (s.contains('completed') || s.contains('delivered')) return 'مكتمل';
    if (s.contains('cancelled')) {
      return s.replaceAll('cancelled', 'مرفوض').replaceAll(':', ' -');
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات بعد.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String id = order['id']?.toString() ?? 'N/A';
    final String type = order['order_type'] ?? 'Delivery';
    final double total = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final String status = order['status'] ?? 'Pending';
    final String? rejectionReason = order['rejection_reason'];

    Color statusColor = Colors.grey;
    if (status == 'Pending' || status == 'قيد الانتظار') {
      statusColor = Colors.orange;
    } else if (status == 'Preparing' || status == 'جاري التحضير') {
      statusColor = Colors.blue;
    } else if (status == 'Completed' ||
        status == 'Delivered' ||
        status == 'مكتمل') {
      statusColor = Colors.green;
    } else if (status == 'Cancelled' || status == 'ملغى') {
      statusColor = Colors.red;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${id.length > 6 ? id.substring(0, 6) : id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                    _getLocalizedStatus(order['status'] ?? ''),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      type == 'Delivery' ? Icons.two_wheeler : Icons.storefront,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _translateText(type),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            if ((status == 'Cancelled' || status == 'ملغى') &&
                rejectionReason != null &&
                rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50], // Light red background
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'تم رفض الطلب: $rejectionReason',
                  style: TextStyle(
                    color: Colors.red[900], // Dark red text
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
