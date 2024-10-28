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
            child: ListView.builder(
              itemCount: 4, // You can increase or decrease this count
              itemBuilder: (context, index) {
                return EventCard();
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
        ),
      ),
    );
  }
}
