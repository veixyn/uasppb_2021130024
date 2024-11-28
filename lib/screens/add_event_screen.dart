import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class AddEventForm extends StatefulWidget {
  @override
  _AddEventFormState createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _summaryController = TextEditingController();
  final _eventHostController = TextEditingController();
  final _cityController = TextEditingController();
  final _quotaController = TextEditingController();
  DateTime? _selectedDateTime;
  Uint8List? _selectedImageBytes;
  String? _selectedEventType;

  // Function to select an image from the gallery and convert to bytes
  Future<void> _pickImage() async {
    // Use file_picker for cross-platform file selection
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image, // Restrict to image files
      withData: true,       // Get the file bytes
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImageBytes = result.files.first.bytes; // Get image bytes
      });
    }
  }


  // Function to select date and time
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  // Function to save event data to Firestore, including the image as base64
  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate() &&
        _selectedDateTime != null &&
        _selectedEventType != null) {
      try {
        final imageBase64 = _selectedImageBytes != null
            ? base64Encode(_selectedImageBytes!)
            : null;

        await FirebaseFirestore.instance.collection('events').add({
          'eventName': _eventNameController.text.trim(),
          'summary': _summaryController.text.trim(),
          'eventHost': _eventHostController.text.trim(),
          'city': _cityController.text.trim(),
          'quota': int.parse(_quotaController.text.trim()),
          'registrants': [],
          'startingTime': _selectedDateTime,
          'eventType': _selectedEventType,
          'imageBase64': imageBase64,
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event added successfully!")),
        );
        _formKey.currentState!.reset();
        setState(() {
          _eventNameController.text = '';
          _summaryController.text = '';
          _eventHostController.text = '';
          _cityController.text = '';
          _quotaController.text = '';
          _selectedDateTime = null;
          _selectedImageBytes = null;
          _selectedEventType = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add event: $e")),
        );
      }
    } else if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a starting time")),
      );
    } else if (_selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an event type")),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
      prefixIcon: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: isDarkMode ? Colors.white38 : Colors.black54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: isDarkMode ? Colors.blue[300]! : Colors.blue, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      filled: true,
      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200], // Background color for inputs
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _eventNameController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration('Event Name', Icons.event),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration('Summary', Icons.description),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a summary';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventHostController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration('Event Host', Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event host';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration('City', Icons.location_city),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quotaController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration('Quota', Icons.people),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quota';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration('Event Type', Icons.category),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'seminar', child: Text('Seminar')),
                  DropdownMenuItem(value: 'online', child: Text('Online')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an event type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedDateTime == null
                      ? 'Select Starting Time'
                      : 'Starting Time: ${_selectedDateTime.toString()}',
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _selectedImageBytes != null
                      ? Image.memory(
                    _selectedImageBytes!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 100,
                    height: 100,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Select Image"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveEvent,
                child: const Text("Save Event"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
