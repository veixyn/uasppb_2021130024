import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uasppb_2021130024/screens/edit_event_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final bool isAdmin;
  final String eventTitle;
  final String eventHost;
  final DateTime? startingTime;
  final int quota;
  final String summary;
  final String? imageBase64;
  final String documentId;
  final VoidCallback onEventUpdated;

  const EventDetailsScreen({
    super.key,
    required this.isAdmin,
    required this.documentId,
    required this.eventTitle,
    required this.summary,
    required this.eventHost,
    required this.startingTime,
    required this.quota,
    this.imageBase64,
    required this.onEventUpdated,
  });

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late String eventTitle;
  late String eventHost;
  DateTime? startingTime;
  late int quota;
  late String summary;
  String? imageBase64;

  bool isRegistered = false; // Track registration status
  String? userId; // Store actual user ID
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize with values from widget
    eventTitle = widget.eventTitle;
    eventHost = widget.eventHost;
    startingTime = widget.startingTime;
    quota = widget.quota;
    summary = widget.summary;
    imageBase64 = widget.imageBase64;

    _checkRegistrationStatus();
    _fetchCurrentUserId();
  }

  Future<void> _fetchCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid; // Set the actual user ID
      });
      _checkRegistrationStatus();
    }
  }

  Future<void> _checkRegistrationStatus() async {
    final eventDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.documentId)
        .get();

    if (eventDoc.exists) {
      List<dynamic> registrants = eventDoc.data()?['registrants'] ?? [];
      setState(() {
        isRegistered = registrants.contains(currentUser?.uid);
      });
    }
  }

  Future<void> _registerOrUnregister() async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.documentId);

    if (isRegistered) {
      await eventRef.update({
        'registrants': FieldValue.arrayRemove([currentUser?.uid]),
      });
    } else {
      await eventRef.update({
        'registrants': FieldValue.arrayUnion([currentUser?.uid]),
      });
    }

    setState(() {
      isRegistered = !isRegistered;
    });

    widget.onEventUpdated();

    Navigator.pop(context, true);
  }

  Future<void> _navigateAndEditEvent(BuildContext context) async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditEventScreen(
              documentId: widget.documentId,
              currentTitle: eventTitle,
              currentHost: eventHost,
              currentStartingTime: startingTime,
              currentQuota: quota,
              currentSummary: summary,
              currentImageBase64: imageBase64,
            ),
      ),
    );

    // If updatedData is returned, update the state
    if (updatedData != null) {
      setState(() {
        eventTitle = updatedData['eventName'];
        eventHost = updatedData['eventHost'];
        startingTime = updatedData['startingTime'];
        quota = updatedData['quota'];
        summary = updatedData['summary'];
        imageBase64 = updatedData['imageBase64'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                image: imageBase64 != null
                    ? DecorationImage(
                  image: MemoryImage(base64Decode(imageBase64!)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              eventTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              eventHost,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${startingTime?.toString()}   |   Quota: $quota",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  summary,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isAdmin)
              _buildAdminButtons(context) // Display admin buttons if user is admin
            else
            // Display the register/unregister button for non-admin users
              isRegistered ? _buildUnregisterButton() : _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButtons(BuildContext screenContext) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => _navigateAndEditEvent(screenContext),
          child: const Text("Edit"),
        ),
        ElevatedButton(
          onPressed: () {
            // Show confirmation dialog before deleting
            showDialog(
              context: screenContext,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Confirm Delete"),
                  content: const Text(
                      "Are you sure you want to delete this event?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      // Close the dialog
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context)
                            .pop(); // Close the confirmation dialog

                        // Delete the event from Firestore
                        try {
                          await FirebaseFirestore.instance
                              .collection(
                              'events') // Replace 'events' with your collection name
                              .doc(widget.documentId)
                              .delete();

                          // Show success message
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            const SnackBar(
                                content: Text("Event deleted successfully!")),
                          );

                          // Close the EventDetailsScreen after deletion
                          Navigator.of(screenContext).pop();
                        } catch (e) {
                          // Show error message if deletion fails
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            SnackBar(
                                content: Text("Failed to delete event: $e")),
                          );
                        }
                      },
                      child: const Text("Delete"),
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Delete", style: TextStyle(color: Colors.white),),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _registerOrUnregister, // Call the register/unregister function
      child: const Text('Register'),
    );
  }

  Widget _buildUnregisterButton() {
    return ElevatedButton(
      onPressed: _registerOrUnregister, // Call the register/unregister function
      child: const Text('Unregister'),
    );
  }
}
