import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditEventScreen extends StatefulWidget {
  final String documentId;
  final String currentTitle;
  final String currentHost;
  final DateTime? currentStartingTime;
  final int currentQuota;
  final String currentSummary;
  final String? currentImageBase64;

  const EditEventScreen({
    Key? key,
    required this.documentId,
    required this.currentTitle,
    required this.currentHost,
    required this.currentStartingTime,
    required this.currentQuota,
    required this.currentSummary,
    this.currentImageBase64,
  }) : super(key: key);

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _hostController;
  late TextEditingController _quotaController;
  late TextEditingController _summaryController;
  DateTime? _selectedStartingTime;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _hostController = TextEditingController(text: widget.currentHost);
    _quotaController = TextEditingController(text: widget.currentQuota.toString());
    _summaryController = TextEditingController(text: widget.currentSummary);
    _selectedStartingTime = widget.currentStartingTime;
    _imageBase64 = widget.currentImageBase64;
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartingTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedStartingTime ?? DateTime.now()),
    );
    if (selectedTime == null) return;

    setState(() {
      _selectedStartingTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedEvent = {
          'eventName': _titleController.text,
          'eventHost': _hostController.text,
          'startingTime': _selectedStartingTime,
          'quota': int.parse(_quotaController.text),
          'summary': _summaryController.text,
          'imageBase64': _imageBase64,
        };

        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.documentId)
            .update(updatedEvent);

        Navigator.pop(context, updatedEvent); // Return updated data
      } catch (e) {
        // Show error message if saving fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save changes: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hostController.dispose();
    _quotaController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Event Title"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(labelText: "Event Host"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the host name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quotaController,
                decoration: const InputDecoration(labelText: "Quota"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quota';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: "Summary"),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a summary';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedStartingTime != null
                      ? "Starting Time: ${_selectedStartingTime!.toLocal()}"
                      : "Select Starting Time",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDateTime(context),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

