import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uasppb_2021130024/component/event_card.dart';
import 'package:uasppb_2021130024/screens/event_details.dart';

class FinishedEventsScreen extends StatelessWidget {
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
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allEvents = [];
  List<DocumentSnapshot> _filteredEvents = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String _selectedEventType = 'All'; // Default filter type

  @override
  void initState() {
    super.initState();
    _fetchFinishedEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFinishedEvents() async {
    final currentTime = DateTime.now();

    final finishedEvents = await FirebaseFirestore.instance
        .collection('events')
        .where('startingTime', isLessThanOrEqualTo: currentTime)
        .get();

    setState(() {
      _allEvents = finishedEvents.docs;
      _filteredEvents = finishedEvents.docs; // Initially, show all events
      _isLoading = false;
    });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _isSearching = true; // Show the loading indicator during filtering
    });

    Future.delayed(const Duration(milliseconds: 1), () {
      setState(() {
        if (query.isEmpty) {
          _filteredEvents = _allEvents.where((event) {
            if (_selectedEventType == 'All') return true;
            return event['eventType'] == _selectedEventType.toLowerCase();
          }).toList();
        } else {
          _filteredEvents = _allEvents.where((event) {
            final eventName = event['eventName']?.toString().toLowerCase() ?? '';
            final eventHost = event['eventHost']?.toString().toLowerCase() ?? '';
            final matchesQuery =
                eventName.contains(query) || eventHost.contains(query);

            if (_selectedEventType == 'All') return matchesQuery;
            return matchesQuery && event['eventType'] == _selectedEventType.toLowerCase();
          }).toList();
        }
        _isSearching = false; // Hide the loading indicator once filtering is done
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Finished Events Header
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

          // Search Bar and Filter Dropdown
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
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

          // Events List or CircularProgressIndicator
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _filteredEvents.isEmpty
                ? const Center(
              child: Text("No matching events found"),
            )
                : ListView.builder(
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                final event = _filteredEvents[index];
                final documentId = event.id;
                final Timestamp? startingTimestamp =
                event['startingTime'];
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
                          hideRegistrationButton:
                          true,
                          documentId: documentId,
                          eventTitle:
                          event['eventName'] ?? 'No Title',
                          summary:
                          event['summary'] ?? 'No Summary',
                          eventHost:
                          event['eventHost'] ?? 'Unknown Host',
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
            ),
          ),
        ],
      ),
    );
  }
}

