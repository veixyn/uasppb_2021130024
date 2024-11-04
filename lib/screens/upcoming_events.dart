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
    UpcomingEvents(),
    FinishedEventsScreen(),
    MyEventsScreen(),
  ];

  // Function to handle navigation
  void _onItemTapped(int index) async {
    if (index == 3) {
      // Call sign-out logic if the "Logout" item is tapped
      await _signOut(context);
    } else {
      // Update selected index for other items
      setState(() {
        _selectedIndex = index;
      });
    }
  }

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
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return EventCard();
            },
          ),
        ),
      ],
    );
  }
}

// Reusable EventCard widget
class EventCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2.0,
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            color: Colors.grey[300], // Placeholder for image
          ),
          title: const Text('Event Title'),
          subtitle: const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventDetailsScreen()),
            );
          }
        ),
      ),
    );
  }
}
