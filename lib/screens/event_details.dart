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

  EventDetailsScreen({
    required this.isAdmin,
    required this.eventTitle,
    required this.eventHost,
    required this.startingTime,
    required this.quota,
    required this.summary,
    required this.imageBase64,
    required this.documentId,
    required VoidCallback onEventUpdated,
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
    if (userId != null) {
      try {
        final eventSnapshot = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.documentId)
            .get();

        if (eventSnapshot.exists) {
          final data = eventSnapshot.data();
          final registrants = data?['registrants'];

          // Ensure registrants is treated as a list or fallback to an empty list
          final List<dynamic> registrantsList =
          registrants is List<dynamic> ? registrants : [];

          setState(() {
            // Check if the user ID exists in the registrants list
            isRegistered = registrantsList.contains(userId);
          });
        } else {
          setState(() {
            isRegistered = false;
          });
        }
      } catch (e) {
        print('Error checking registration status: $e');
        setState(() {
          isRegistered = false;
        });
      }
    }
  }


  Future<void> _registerForEvent() async {
    if (userId != null) {
      try {
        final eventDocRef = FirebaseFirestore.instance
            .collection('events')
            .doc(widget.documentId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(eventDocRef);

          if (snapshot.exists) {
            final data = snapshot.data();
            final registrants = data?['registrants'];

            // Ensure registrants is treated as a list
            final List<dynamic> registrantsList =
            registrants is List<dynamic> ? registrants : [];

            // Add the user ID if not already registered
            if (!registrantsList.contains(userId)) {
              registrantsList.add(userId);
            }

            transaction.update(eventDocRef, {'registrants': registrantsList});
          }
        });

        setState(() {
          isRegistered = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully registered!')),
        );
      } catch (e) {
        print('Error registering for event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $e')),
        );
      }
    }
  }


  Future<void> _cancelRegistration(String documentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Remove the user UID from the registrants array
      await FirebaseFirestore.instance.collection('events').doc(documentId).update({
        'registrants': FieldValue.arrayRemove([user.uid]),
      });

      print("Successfully unregistered from the event.");
    } catch (e) {
      print("Error unregistering from event: $e");
      throw Exception("Failed to unregister from the event.");
    }
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
            widget.isAdmin
                ? _buildAdminButtons(context)
                : isRegistered
                ? _buildCancelButton()
                : _buildRegisterButton()
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
      onPressed: _registerForEvent,
      child: const Text("Register for this Event"),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: () async {
        try {
          await _cancelRegistration(widget.documentId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Successfully unregistered from the event")),
          );
          Navigator.pop(context, true); // Notify the previous screen to refresh
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to unregister: $e")),
          );
        }
      },
      child: const Text("Cancel Registration"),
    );
  }
}