import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Map<String, String> week = {
      'Mon': 'Push',
      'Tue': 'Rest',
      'Wed': 'Pull',
      'Thu': 'Rest',
      'Fri': 'Legs',
      'Sat': 'Cardio',
      'Sun': 'Rest',
    };

    final entries = week.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Calendar')),
      body: ListView.separated(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(entry.key),
            subtitle: Text(entry.value),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }
}

