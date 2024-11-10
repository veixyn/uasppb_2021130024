import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uasppb_2021130024/screens/add_event_screen.dart';
import 'package:uasppb_2021130024/screens/event_details.dart';
import 'package:uasppb_2021130024/screens/login_screen.dart';

class AdminScreen extends StatelessWidget {
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
    AllEvents(refreshEvents: () {  },),
    AddEventForm(),
  ];

  // Function to handle navigation
  void _onItemTapped(int index) async {
    if (index == 2) {
      _confirmSignOut(context);
    } else {
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
                Navigator.of(context).pop();
                _signOut(context);
              },
              child: const Text("Sign Out"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  void _refreshEvents() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dicoding Events'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AllEvents(refreshEvents: _refreshEvents),
          AddEventForm(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'All Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Add New Event',
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
class AllEvents extends StatelessWidget {
  final VoidCallback refreshEvents;

  const AllEvents({Key? key, required this.refreshEvents}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'All Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No events found.'));
              }
              final events = snapshot.data!.docs;

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
                            isAdmin: true,
                            documentId: documentId,
                            eventTitle: event['eventName'] ?? 'No Title',
                            summary: event['summary'] ?? 'No Summary',
                            eventHost: event['eventHost'] ?? 'Unknown Host',
                            startingTime: startingTime,
                            quota: event['quota'] ?? 0,
                            imageBase64: event['imageBase64'],
                            onEventUpdated: refreshEvents,
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
