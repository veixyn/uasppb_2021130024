import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisteredUsersPage extends StatefulWidget {
  final String documentId;

  const RegisteredUsersPage({Key? key, required this.documentId}) : super(key: key);

  @override
  _RegisteredUsersPageState createState() => _RegisteredUsersPageState();
}

class _RegisteredUsersPageState extends State<RegisteredUsersPage> {
  late Future<List<Map<String, dynamic>>> _registeredUsersFuture;
  DateTime? _startingTime;

  @override
  void initState() {
    super.initState();
    _registeredUsersFuture = _fetchRegisteredUsers();
    _fetchStartingTime();
  }

  Future<void> _fetchStartingTime() async {
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(widget.documentId).get();
    final startingTimestamp = eventDoc['startingTime'] as Timestamp?;
    setState(() {
      _startingTime = startingTimestamp?.toDate();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchRegisteredUsers() async {
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(widget.documentId).get();
    final registrants = List<String>.from(eventDoc['registrants'] ?? []);

    if (registrants.isEmpty) return [];

    // Fetch user details from Firestore
    final usersQuery = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: registrants)
        .get();

    return usersQuery.docs.map((doc) => doc.data()).toList();
  }

  Future<void> _removeUserFromEvent(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.documentId).update({
        'registrants': FieldValue.arrayRemove([userId]),
      });

      setState(() {
        _registeredUsersFuture = _fetchRegisteredUsers(); // Refresh the list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User removed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove user: $e")),
      );
    }
  }

  void _showConfirmationDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Removal"),
          content: Text("Are you sure you want to remove $userName from this event?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _removeUserFromEvent(userId);
              },
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEventStarted = _startingTime != null && DateTime.now().isAfter(_startingTime!);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registered Users"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _registeredUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading registered users"));
          }

          final registeredUsers = snapshot.data ?? [];

          if (registeredUsers.isEmpty) {
            return const Center(child: Text("No users have registered for this event"));
          }

          return ListView.builder(
            itemCount: registeredUsers.length,
            itemBuilder: (context, index) {
              final user = registeredUsers[index];
              final userName = user['name'] ?? 'Unknown User';
              final userEmail = user['email'] ?? 'No Email';
              final userId = user['uid'];

              return ListTile(
                title: Text(userName),
                subtitle: Text(userEmail),
                trailing: hasEventStarted
                    ? null // Hide the remove button if the event has started
                    : IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    _showConfirmationDialog(userId, userName);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
