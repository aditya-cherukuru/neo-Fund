import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notificationService.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _notificationService.clearAll();
                });
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: _notificationService.notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notificationService.notifications.length,
              itemBuilder: (context, index) {
                final notification = _notificationService.notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you about important updates',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final timestamp = DateTime.parse(notification['timestamp']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? AppTheme.cardBackground : AppTheme.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.transparent : AppTheme.accentGreen.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification['type']).withOpacity(0.2),
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: _getNotificationColor(notification['type']),
          ),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['message']),
            const SizedBox(height: 4),
            Text(
              AppHelpers.getTimeAgo(timestamp),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            setState(() {
              _notificationService.markAsRead(notification['id']);
            });
          }
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'NotificationType.investment':
        return AppTheme.accentGreen;
      case 'NotificationType.achievement':
        return Colors.amber;
      case 'NotificationType.market':
        return AppTheme.accentBlue;
      case 'NotificationType.social':
        return AppTheme.primaryPurple;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'NotificationType.investment':
        return Icons.trending_up;
      case 'NotificationType.achievement':
        return Icons.emoji_events;
      case 'NotificationType.market':
        return Icons.show_chart;
      case 'NotificationType.social':
        return Icons.group;
      default:
        return Icons.notifications;
    }
  }
}
