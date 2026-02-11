import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgramDetailsScreen extends StatelessWidget {
  const ProgramDetailsScreen({super.key, required this.program});

  final dynamic program;

  @override
  Widget build(BuildContext context) {
    final routines = program['routines'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(program['name'] ?? 'Program')),
      body: routines.isEmpty
          ? const Center(child: Text('No routines yet'))
          : ListView.builder(
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(routine['name'] ?? 'Unnamed'),
                    subtitle: Text('Scheduled: ${routine['day'] ?? 'N/A'}'),
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