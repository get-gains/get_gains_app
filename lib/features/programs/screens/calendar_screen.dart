import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final week = {
      'Mon': 'Push',
      'Tue': 'Rest',
      'Wed': 'Pull',
      'Thu': 'Rest',
      'Fri': 'Legs',
      'Sat': 'Cardio',
      'Sun': 'Rest',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Calendar')),
      body: ListView(
        children: week.entries.map((entry) {
          return ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(entry.key),
            subtitle: Text(entry.value),
          );
        }).toList(),
      ),
    );
  }
}

