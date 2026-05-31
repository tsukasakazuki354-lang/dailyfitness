import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/notification_model.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please sign in to view notifications')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.notifications().where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final notifications = (snapshot.data?.docs ?? []).map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.black26),
                  SizedBox(height: 16),
                  Text('No notifications', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  SizedBox(height: 8),
                  Text('You\'re all caught up!', style: TextStyle(color: Colors.black38)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(notification: notif);
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(String uid) async {
    final snapshot = await FirestoreService.notifications().where('userId', isEqualTo: uid).where('isRead', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  IconData _iconForType(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long;
      case 'promo':
        return Icons.local_offer;
      case 'delivery':
        return Icons.local_shipping;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead ? null : const Color(0xFFF0F7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead ? Colors.grey.shade100 : const Color(0xFFE5F2FF),
          child: Icon(_iconForType(notification.type), color: notification.isRead ? Colors.black38 : const Color(0xFF0F2850), size: 20),
        ),
        title: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
        subtitle: Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: notification.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4AB3F4), shape: BoxShape.circle)),
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  Future<void> _markAsRead(NotificationModel notif) async {
    if (notif.isRead) return;
    final query = await FirestoreService.notifications().where('notificationId', isEqualTo: notif.notificationId).get();
    for (final doc in query.docs) {
      await doc.reference.update({'isRead': true});
    }
  }
}
