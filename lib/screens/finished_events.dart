import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uasppb_2021130024/screens/event_details.dart';

void main() {
  runApp(FinishedEventsScreen());
}

class FinishedEventsScreen extends StatelessWidget {
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
  Future<List<DocumentSnapshot>> _fetchFinishedEvents() async {
    final currentTime = DateTime.now();

    final finishedEvents = await FirebaseFirestore.instance
        .collection('events')
        .where('startingTime', isLessThanOrEqualTo: currentTime)
        .get();

    return finishedEvents.docs;
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
                'Finished Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchFinishedEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading events"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No finished events"));
                }

                final events = snapshot.data!;
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final documentId = event.id;
                    final Timestamp? startingTimestamp = event['startingTime'];
                    final startingTime = startingTimestamp?.toDate();

                    return EventCard(
                      documentId: documentId,
                      title: event['eventName'] ?? 'No Title',
                      summary: event['summary'] ?? 'No Summary',
                      host: event['eventHost'] ?? 'Unknown Host',
                      startingTime: startingTime,
                      quota: event['quota'] ?? 0,
                      imageBase64: event['imageBase64'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailsScreen(
                              isAdmin: false,
                              hideRegistrationButton: true, // Add this line
                              documentId: documentId,
                              eventTitle: event['eventName'] ?? 'No Title',
                              summary: event['summary'] ?? 'No Summary',
                              eventHost: event['eventHost'] ?? 'Unknown Host',
                              startingTime: startingTime,
                              quota: event['quota'] ?? 0,
                              imageBase64: event['imageBase64'],
                              onEventUpdated: () {},
                            ),
                          ),
                        );
                      },
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
  final String summary;
  final String host;
  final DateTime? startingTime;
  final int quota;
  final String? imageBase64;
  final VoidCallback onTap;

  const EventCard({
    Key? key,
    required this.title,
    required this.summary,
    required this.host,
    required this.startingTime,
    required this.quota,
    this.imageBase64,
    required this.onTap,
    required String documentId,
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
            color: Colors.grey[300],
          ),
          title: Text(title),
          subtitle: Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            startingTime != null
                ? '${startingTime!.day}-${startingTime!.month}-${startingTime!.year} ${startingTime!.hour}:${startingTime!.minute}'
                : 'No Time',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
