import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyEventsScreen());
}

class MyEventsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dicoding Events',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final String userId = "currentUserId"; // Replace with the actual current user ID

  Future<List<DocumentSnapshot>> _fetchRegisteredEvents() async {
    final registrations = await FirebaseFirestore.instance
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .get();

    final eventIds = registrations.docs.map((doc) => doc['eventId']).toList();

    if (eventIds.isEmpty) return []; // Return empty list if no registrations

    final events = await FirebaseFirestore.instance
        .collection('events')
        .where(FieldPath.documentId, whereIn: eventIds)
        .get();

    return events.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchRegisteredEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading events"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No registered events"));
                }

                final events = snapshot.data!;
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      title: event['eventName'],
                      description: event['summary'],
                      imageBase64: event['imageBase64'], // Optional
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageBase64; // Optional for displaying an image

  const EventCard({
    Key? key,
    required this.title,
    required this.description,
    this.imageBase64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2.0,
        child: ListTile(
          leading: imageBase64 != null
              ? Image.memory(
            base64Decode(imageBase64!),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : Container(
            width: 50,
            height: 50,
            color: Colors.grey[300], // Placeholder for image
          ),
          title: Text(title),
          subtitle: Text(description),
        ),
      ),
    );
  }
}
