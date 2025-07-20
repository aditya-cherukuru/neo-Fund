import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

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
      ),
      body: _notificationService.notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications',
                style: TextStyle(fontSize: 18),
              ),
            )
          : const Center(
              child: Text(
                'Notifications loaded',
                style: TextStyle(fontSize: 18),
              ),
            ),
    );
  }
}
