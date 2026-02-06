import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgramDetailsScreen extends StatelessWidget {
  const ProgramDetailsScreen({super.key, required this.program});

  final Map program;

  @override
  Widget build(BuildContext context) {
    // TEMP fake routines
    final routines = [
      {'day': 'Monday', 'name': 'Push Day'},
      {'day': 'Wednesday', 'name': 'Pull Day'},
      {'day': 'Friday', 'name': 'Leg Day'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(program['name'])),
      body: ListView.builder(
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(routine['name']!),
              subtitle: Text('Scheduled: ${routine['day']}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () {
                context.push('/calendar');
              },
            ),
          );
        },
      ),
    );
  }
}
