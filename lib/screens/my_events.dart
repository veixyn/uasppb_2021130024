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
      home: HomePage(refreshEvents: () {}),
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
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allEvents = [];
  List<DocumentSnapshot> _filteredEvents = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String _selectedEventType = 'All';

  @override
  void initState() {
    super.initState();
    _refreshFuture = Future.value();
    _fetchRegisteredEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegisteredEvents() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _allEvents = [];
        _filteredEvents = [];
        _isLoading = false;
      });
      return;
    }

    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('registrants', arrayContains: user.uid)
        .get();

    setState(() {
      _allEvents = eventsSnapshot.docs;
      _filteredEvents = eventsSnapshot.docs;
      _isLoading = false;
    });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 1), () {
      setState(() {
        if (query.isEmpty) {
          _filteredEvents = _allEvents.where((event) {
            if (_selectedEventType == 'All') return true;
            return event['eventType'] == _selectedEventType;
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
        _isSearching = false;
      });
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshFuture = Future.delayed(const Duration(milliseconds: 500));
    });
    _fetchRegisteredEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 1.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedEventType,
                      underline: const SizedBox(),
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
                          _filterEvents();
                        }
                      },
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                      dropdownColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredEvents.isEmpty
                  ? const Center(child: Text("No matching events found"))
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
                    onTap: () async {
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsScreen(
                            isAdmin: false,
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
                            onEventUpdated: widget.refreshEvents,
                            hideRegistrationButton: startingTime !=
                                null &&
                                startingTime.isBefore(DateTime.now()),
                          ),
                        ),
                      );

                      if (shouldRefresh == true) {
                        widget.refreshEvents();
                      }
                    },
                  );
                },
              ),
            ),
          ],
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
