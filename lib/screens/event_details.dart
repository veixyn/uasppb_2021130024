import 'package:flutter/material.dart';
import 'dart:convert';

class EventDetailsScreen extends StatelessWidget {
  final String title;
  final String host;
  final String startingTime;
  final int quota;
  final String summary;
  final String? imageBase64;

  const EventDetailsScreen({
    Key? key,
    required this.title,
    required this.host,
    required this.startingTime,
    required this.quota,
    required this.summary,
    this.imageBase64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display event image if available
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
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              host,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),

            // Event Details (Time and Quota)
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

            // Event Summary/Description
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

            // Register Button
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm Registration"),
                      content: const Text("Are you sure you want to register for this event?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            // Add your registration logic here
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                "Register for this Event",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
