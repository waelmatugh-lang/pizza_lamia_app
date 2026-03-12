import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/notification_cubit.dart';
import 'cubit/notification_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر تحديث القائمة
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () =>
                context.read<NotificationCubit>().listenToNotifications(),
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5722)),
            );
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (state is NotificationSuccess) {
            if (state.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: Colors.grey,
                      size: 72,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات حالياً',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ستظهر هنا إشعارات طلباتك وعروضنا',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notifications.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final notif = state.notifications[index];
                final isRead = notif['is_read'] as bool? ?? true;
                final title = notif['title'] as String? ?? 'إشعار';
                final body = notif['body'] as String? ?? '';
                final id = notif['id'].toString();
                final createdAt = notif['created_at'] as String? ?? '';

                return InkWell(
                  onTap: isRead
                      ? null
                      : () => context.read<NotificationCubit>().markAsRead(id),
                  child: Container(
                    color: isRead
                        ? Colors.transparent
                        : const Color(0xFFFF5722).withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // أيقونة + نقطة غير مقروء
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isRead
                                    ? Colors.grey[900]
                                    : const Color(
                                        0xFFFF5722,
                                      ).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: isRead
                                    ? Colors.grey
                                    : const Color(0xFFFF5722),
                                size: 22,
                              ),
                            ),
                            if (!isRead)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5722),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        // محتوى الإشعار
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      return 'منذ ${diff.inDays} يوم';
    } catch (_) {
      return '';
    }
  }
}
