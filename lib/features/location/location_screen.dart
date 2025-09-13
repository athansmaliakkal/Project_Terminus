import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:terminus/services/file_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final FileService _fileService = FileService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<Map<String, dynamic>> _logData = [];

  @override
  void initState() {
    super.initState();
    _loadDataForSelectedDate();
  }

  Future<void> _loadDataForSelectedDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final file = await _fileService.getLogFileForDate(_selectedDate);
      final content = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(content);
      
      if (mounted) {
        setState(() {
          _logData = List<Map<String, dynamic>>.from(jsonData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logData = [];
          _isLoading = false;
        });
      }
      debugPrint("Could not load log file for $_selectedDate: $e");
    }
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).size.height / 3,
          color: const Color.fromARGB(255, 0, 0, 0),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (picked) {
              if (picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            initialDateTime: _selectedDate,
            minimumDate: DateTime(2024, 1, 1), 
            maximumDate: DateTime.now(),
          ),
        );
      },
    ).whenComplete(() {
      _loadDataForSelectedDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text('LOCATION HISTORY', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              onPressed: _showDatePicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 28),
                  const SizedBox(width: 16),
                  Text(
                    DateFormat('d MMMM yyyy').format(_selectedDate),
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _logData.isEmpty
                      ? const Center(
                          child: Text(
                            'No location data found for this date.',
                            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16),
                          ),
                        )
                      : _buildDataSummary(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_logData.length} data points recorded.',
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.map),
          label: const Text('VIEW ROUTE ON MAP'),
          onPressed: () {
            if (_logData.isNotEmpty) {
              Navigator.pushNamed(
                context,
                '/fullscreen-map',
                arguments: _logData,
              );
            }
          },
        ),
      ],
    );
  }
}

