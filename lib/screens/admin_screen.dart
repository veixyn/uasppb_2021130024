import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uasppb_2021130024/component/event_card.dart';
import 'package:uasppb_2021130024/provider/theme_provider.dart';
import 'package:uasppb_2021130024/screens/add_event_screen.dart';
import 'package:uasppb_2021130024/screens/event_details.dart';
import 'package:uasppb_2021130024/screens/login_screen.dart';

class AdminScreen extends StatelessWidget {
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
    AllEvents(refreshEvents: () {}),
    AddEventForm(),
  ];

  void _onItemTapped(int index) async {
    if (index == 2) {
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

  void _refreshEvents() {
    setState(() {});
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: isDarkMode ? Colors.grey[600] : Colors.grey,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'All Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task_outlined),
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


// "Upcoming Events" Page with Search Bar
class AllEvents extends StatefulWidget {
  final VoidCallback refreshEvents;

  const AllEvents({Key? key, required this.refreshEvents}) : super(key: key);

  @override
  _AllEventsState createState() => _AllEventsState();
}

class _AllEventsState extends State<AllEvents> {
  String _searchQuery = '';
  String _selectedEventType = 'All'; // Default to 'All'
  final TextEditingController _searchController = TextEditingController();

  final List<String> _eventTypes = ['All', 'Seminar', 'Online'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search events...',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200], // Dynamic background color
            ),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black, // Input text color
            ),
          ),
        ),

// Event Type Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedEventType,
            items: _eventTypes.map((eventType) {
              return DropdownMenuItem(
                value: eventType,
                child: Text(
                  eventType,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black, // Dropdown item text color
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEventType = value!;
              });
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200], // Dynamic background color
            ),
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.white, // Dropdown menu background
          ),
        ),
        // Event List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .orderBy('startingTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No events found.'));
              }

              final events = snapshot.data!.docs.where((event) {
                final eventName =
                (event['eventName'] ?? '').toString().toLowerCase();
                final eventType =
                (event['eventType'] ?? '').toString().toLowerCase();
                final matchesSearch = eventName.contains(_searchQuery);
                final matchesType = _selectedEventType == 'All' ||
                    eventType == _selectedEventType.toLowerCase();
                return matchesSearch && matchesType;
              }).toList();

              if (events.isEmpty) {
                return const Center(
                  child: Text(
                    'No matching events found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

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
                            onEventUpdated: widget.refreshEvents,
                            hideRegistrationButton: false,
                            eventType: event['eventType'] ?? 'Unknown Type',
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
