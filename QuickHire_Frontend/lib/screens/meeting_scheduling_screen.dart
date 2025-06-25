import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Meeting_Scheduling_Screen extends StatefulWidget {
  // If using named routes, you can reference "MeetingSchedulingScreen.id"
  static const String id = 'Meeting_Scheduling_Screen';

  const Meeting_Scheduling_Screen({super.key});

  @override
  State<Meeting_Scheduling_Screen> createState() => _MeetingSchedulingScreenState();
}

class _MeetingSchedulingScreenState extends State<Meeting_Scheduling_Screen> {
  // Meeting type choices
  final List<String> _meetingTypes = [
    'Video Call',
    'Phone Call',
    'In-person Meeting'
  ];
  String _selectedMeetingType = 'Video Call';

  // Calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Durations
  final List<String> _durations = ['15 min', '30 min', '45 min', '60 min'];
  String _selectedDuration = '30 min';

  // Time zones
  final List<String> _timeZones = [
    'Pacific Time - US & Canada',
    'Mountain Time - US & Canada',
    'Central Time - US & Canada',
    'Eastern Time - US & Canada',
    'UTC'
  ];
  String _selectedTimeZone = 'Pacific Time - US & Canada';

  // Hour selection
  String? _selectedTime;
  final List<String> _allHours = List.generate(
    24,
        (index) => '${index.toString().padLeft(2, '0')}:00',
  );

  @override
  void initState() {
    super.initState();
    // By default, the selected date is "today"
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Invitations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job detail card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Managing Director',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Systems Limited'),
                    Text('Industry: Tech'),
                    Text('Job Type: Design'),
                    Text('Location: NY 1011, Street 13, New York'),
                    Text('Salary range: \$10,000'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Job description card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'It is a long established fact that a reader will be '
                          'distracted by the readable content of a page when looking '
                          'at its layout. The point of using Lorem Ipsum is that it '
                          'has a more-or-less normal distribution of letters...',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Meeting type buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _meetingTypes.map((type) {
                final bool isSelected = (type == _selectedMeetingType);
                return GestureDetector(
                  onTap: () => setState(() => _selectedMeetingType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(type),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Duration
            const Text(
              'Duration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedDuration,
              items: _durations.map((duration) {
                return DropdownMenuItem<String>(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  setState(() => _selectedDuration = newVal);
                }
              },
            ),

            const SizedBox(height: 20),

            // Calendar
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              selectedDayPredicate: (day) => day == _selectedDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),

            const SizedBox(height: 20),

            // Time zone
            const Text(
              'Time Zone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedTimeZone,
              items: _timeZones.map((zone) {
                return DropdownMenuItem<String>(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
              onChanged: (String? val) {
                if (val != null) {
                  setState(() => _selectedTimeZone = val);
                }
              },
            ),

            const SizedBox(height: 20),

            // Select time
            const Text(
              'Please Select Your Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allHours.map((hour) {
                final bool isSelected = hour == _selectedTime;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = hour),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber : Colors.white,
                      border: Border.all(color: isSelected ? Colors.amber : Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(hour),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Submit button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () {
                      // handle submission
                      // e.g., print or send data to backend
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Decline / Chat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // handle decline
                  },
                  child: const Text('Decline'),
                ),
                OutlinedButton(
                  onPressed: () {
                    // handle chat
                  },
                  child: const Text('Chat with Recruiter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
