import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uasppb_2021130024/screens/event_details.dart';

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
      home: HomePage(refreshEvents: () {  },),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback refreshEvents;

  const HomePage({Key? key, required this.refreshEvents}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> _refreshFuture;

  @override
  void initState() {
    super.initState();
    _refreshFuture = Future.value(); // Initial placeholder
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshFuture = Future.delayed(Duration(milliseconds: 500));
    });
  }

  Stream<List<DocumentSnapshot>> _streamRegisteredEvents() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]); // Handle the case where no user is logged in

      // Query the events collection to find events where the user is registered
      return FirebaseFirestore.instance
          .collection('events')
          .where('registrants', arrayContains: user.uid) // Check if user UID is in the "registrants" array
          .snapshots()
          .map((eventSnapshot) => eventSnapshot.docs);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<void>(
          future: _refreshFuture,
          builder: (context, snapshot) {
            return Column(
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
                  child: StreamBuilder<List<DocumentSnapshot>>(
                    stream: _streamRegisteredEvents(),
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
                            onTap: () async {
                              final shouldRefresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailsScreen(
                                    isAdmin: false,
                                    documentId: documentId,
                                    eventTitle: event['eventName'] ?? 'No Title',
                                    summary: event['summary'] ?? 'No Summary',
                                    eventHost: event['eventHost'] ?? 'Unknown Host',
                                    startingTime: startingTime,
                                    quota: event['quota'] ?? 0,
                                    imageBase64: event['imageBase64'],
                                    onEventUpdated: widget.refreshEvents,
                                    hideRegistrationButton: false,
                                  ),
                                ),
                              );

                              if (shouldRefresh == true) {
                                widget.refreshEvents(); // Manually trigger the refresh
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
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
