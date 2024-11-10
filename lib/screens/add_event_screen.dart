import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

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
  final ImagePicker _picker = ImagePicker();

  // Function to select an image from the gallery and convert to bytes
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageBytes = File(pickedFile.path).readAsBytesSync();
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
    if (_formKey.currentState!.validate() && _selectedDateTime != null) {
      try {
        // Convert the image to base64 if it exists
        final imageBase64 = _selectedImageBytes != null ? base64Encode(_selectedImageBytes!) : null;

        // Save event data to Firestore
        await FirebaseFirestore.instance.collection('events').add({
          'eventName': _eventNameController.text.trim(),
          'summary': _summaryController.text.trim(),
          'eventHost': _eventHostController.text.trim(),
          'city': _cityController.text.trim(),
          'quota': int.parse(_quotaController.text.trim()),
          'registrants': 0,
          'startingTime': _selectedDateTime,  // Use selected date and time
          'imageBase64': imageBase64,  // Store image as base64
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event added successfully!")),
        );
        _formKey.currentState!.reset();
        setState(() {
          _selectedDateTime = null;
          _selectedImageBytes = null;
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
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Summary'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a summary';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _eventHostController,
                decoration: const InputDecoration(labelText: 'Event Host'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event host';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quotaController,
                decoration: const InputDecoration(labelText: 'Quota'),
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
              ListTile(
                title: Text(
                  _selectedDateTime == null
                      ? 'Select Starting Time'
                      : 'Starting Time: ${_selectedDateTime.toString()}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _selectedImageBytes != null
                      ? Image.memory(_selectedImageBytes!, width: 100, height: 100, fit: BoxFit.cover)
                      : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
