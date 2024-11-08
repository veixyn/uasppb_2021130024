import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
  final bool isAdmin; // New parameter to determine if the user is an admin
  final String eventTitle;
  final String eventHost;
  final String startingTime;
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
      ),
      body: Builder(
        builder: (BuildContext screenContext) {
          return Padding(
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
                // Event Title and Host
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
                  "$startingTime   |   Quota: $quota",
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
                isAdmin ? _buildAdminButtons(screenContext) : _buildUserButton(screenContext),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminButtons(BuildContext screenContext) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            // Edit event logic (if any)
          },
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
                  content: const Text("Are you sure you want to delete this event?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(), // Close the dialog
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close the confirmation dialog

                        // Delete the event from Firestore
                        try {
                          await FirebaseFirestore.instance
                              .collection('events') // Replace 'events' with your collection name
                              .doc(documentId)
                              .delete();

                          // Show success message
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            const SnackBar(content: Text("Event deleted successfully!")),
                          );

                          // Close the EventDetailsScreen after deletion
                          Navigator.of(screenContext).pop();
                        } catch (e) {
                          // Show error message if deletion fails
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            SnackBar(content: Text("Failed to delete event: $e")),
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

  Widget _buildUserButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Registration"),
              content: const Text("Are you sure you want to register for this event?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Successfully registered for the event!")),
                    );
                  },
                  child: const Text("Yes"),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
      child: const Text(
        "Register for this Event",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
