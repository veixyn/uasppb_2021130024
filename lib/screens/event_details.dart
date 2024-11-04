import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Image placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Event Title and Host
            const Text(
              "Event Title",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Event Host",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),

            // Event Details (Time and Quota)
            Text(
              "Event Starting Time   |   Event Quota",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            // Event Description
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                      "Proin ultrices varius justo et auctor. Cras eu gravida nisi. "
                      "Donec pretium ipsum quis felis lacinia dignissim. Phasellus "
                      "vestibulum congue egestas. Maecenas mauris nibh, placerat "
                      "quis ante dignissim, porta egestas turpis. Nulla venenatis "
                      "sapien a eros tincidunt, sit amet pellentesque orci blandit. "
                      "Cras sit amet ex lorem. Mauris a augue leo. Phasellus id "
                      "pellentesque justo, a elementum tortor. Nunc vestibulum ipsum "
                      "ex, id aliquet orci molestie in. In ut orci tempus, vulputate "
                      "velit in, auctor sem. Maecenas dignissim nibh ligula, sit amet "
                      "volutpat felis facilisis ac.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Register Button
            ElevatedButton(
              onPressed: () {
                // Action when button is pressed
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                "Register for this Event",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}