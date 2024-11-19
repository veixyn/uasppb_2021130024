import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uasppb_2021130024/screens/event_details.dart';
import 'package:uasppb_2021130024/screens/finished_events.dart';
import 'package:uasppb_2021130024/screens/login_screen.dart';
import 'package:uasppb_2021130024/screens/my_events.dart';

void main() {
  runApp(UpcomingEventsScreen());
}

class UpcomingEventsScreen extends StatelessWidget {
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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of screens to navigate to
  final List<Widget> _pages = [
    UpcomingEvents(refreshEvents: () {  },),
    FinishedEventsScreen(),
    MyEventsScreen(),
  ];

  // Function to handle navigation
  void _onItemTapped(int index) async {
    if (index == 3) {
      // Show a confirmation dialog before sign-out
      _confirmSignOut(context);
    } else {
      // Update selected index for other items
      setState(() {
        _selectedIndex = index;
      });
    }
  }

// Function to confirm sign-out
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Sign Out"),
          content: const Text("Are you sure you want to sign out?"),
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
                _signOut(context); // Proceed with sign-out
              },
              child: const Text("Sign Out"),
            ),
          ],
        );
      },
    );
  }

// Function to perform the sign-out
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to the LoginScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dicoding Events'),
      ),
      body: _pages[_selectedIndex], // Display the selected page

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex, // Track the selected index
        onTap: _onItemTapped, // Handle item tap
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Upcoming',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Finished',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'My Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}

// "Upcoming Events" Page
class UpcomingEvents extends StatelessWidget {
  final VoidCallback refreshEvents;

  const UpcomingEvents({Key? key, required this.refreshEvents}) : super(key: key);

  Future<List<DocumentSnapshot>> _fetchUpcomingEvents() async {
    final now = DateTime.now();

    final events = await FirebaseFirestore.instance
        .collection('events')
        .where('startingTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('startingTime', descending: true)
        .get();

    return events.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchUpcomingEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading events"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No upcoming events"));
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
                            documentId: documentId,
                            eventTitle: event['eventName'] ?? 'No Title',
                            summary: event['summary'] ?? 'No Summary',
                            eventHost: event['eventHost'] ?? 'Unknown Host',
                            startingTime: startingTime,
                            quota: event['quota'] ?? 0,
                            imageBase64: event['imageBase64'],
                            onEventUpdated: refreshEvents,
                            hideRegistrationButton: false,
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
    );
  }
}

// Reusable EventCard widget
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
