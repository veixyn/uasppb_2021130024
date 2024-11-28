import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uasppb_2021130024/component/event_card.dart';
import 'package:uasppb_2021130024/provider/theme_provider.dart';
import 'package:uasppb_2021130024/screens/event_details.dart';
import 'package:uasppb_2021130024/screens/finished_events.dart';
import 'package:uasppb_2021130024/screens/login_screen.dart';
import 'package:uasppb_2021130024/screens/my_events.dart';
import 'package:provider/provider.dart';

class UpcomingEventsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomePage();
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    UpcomingEvents(refreshEvents: () {}),
    FinishedEventsScreen(),
    MyEventsScreen(),
  ];

  void _onItemTapped(int index) async {
    if (index == 3) {
      _confirmSignOut(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

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
                Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dicoding Events'),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.lightbulb : Icons.lightbulb_outline,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: isDarkMode ? Colors.grey[600] : Colors.grey,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
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
class UpcomingEvents extends StatefulWidget {
  final VoidCallback refreshEvents;

  const UpcomingEvents({Key? key, required this.refreshEvents}) : super(key: key);

  @override
  _UpcomingEventsState createState() => _UpcomingEventsState();
}

class _UpcomingEventsState extends State<UpcomingEvents> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allEvents = [];
  List<DocumentSnapshot> _filteredEvents = [];
  bool _isSearching = false;
  bool _isLoading = true;

  String _selectedEventType = 'All'; // Track selected event type

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUpcomingEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final events = await FirebaseFirestore.instance
          .collection('events')
          .where('startingTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startingTime', descending: true)
          .get();

      setState(() {
        _allEvents = events.docs;
        _filteredEvents = events.docs; // Show all events initially
      });
    } catch (e) {
      print("Error fetching events: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty && _selectedEventType == 'All') {
        _filteredEvents = _allEvents;
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredEvents = _allEvents.where((event) {
          final eventName = event['eventName']?.toString().toLowerCase() ?? '';
          final eventHost = event['eventHost']?.toString().toLowerCase() ?? '';
          final eventType = event['eventType']?.toString().toLowerCase() ?? '';

          final matchesQuery =
              eventName.contains(query) || eventHost.contains(query);
          final matchesType = _selectedEventType == 'All' ||
              eventType.toLowerCase() == _selectedEventType.toLowerCase();

          return matchesQuery && matchesType;
        }).toList();
      }
    });
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search events by name or host...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButton<String>(
                  value: _selectedEventType,
                  underline: const SizedBox(), // Remove default underline
                  items: ['All', 'Online', 'Seminar']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedEventType = value;
                      });
                      _filterEvents(); // Reapply filters
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down), // Add a drop-down arrow icon
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                  dropdownColor: Colors.white, // Background color for dropdown items
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredEvents.isEmpty
              ? const Center(child: Text("No events found"))
              : ListView.builder(
            itemCount: _filteredEvents.length,
            itemBuilder: (context, index) {
              final event = _filteredEvents[index];
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
                        onEventUpdated: widget.refreshEvents,
                        hideRegistrationButton: false,
                      ),
                    ),
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
