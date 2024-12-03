import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('userNotifications')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _notifications = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'message': doc['message'] ?? 'No message',
            'timestamp': doc['timestamp'],
            'readStatus': doc['readStatus'] ?? false,
          };
        }).toList();
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('userNotifications')
          .doc(notificationId)
          .update({'readStatus': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('No notifications available.'))
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final timestamp = notification['timestamp'] as Timestamp?;
          final formattedDate = timestamp != null
              ? timestamp.toDate().toString()
              : 'Unknown';

          return ListTile(
            title: Text(notification['message']),
            subtitle: Text('Date: $formattedDate'),
            trailing: notification['readStatus']
                ? const Icon(Icons.check, color: Colors.green)
                : const Icon(Icons.markunread, color: Colors.red),
            onTap: () {
              if (!notification['readStatus']) {
                // Mark as read only if unread
                _markAsRead(notification['id']).then((_) {
                  setState(() {
                    notification['readStatus'] = true;
                  });
                });
              }
            },
          );
        },
      ),
    );
  }
}
