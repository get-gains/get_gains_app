import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/router_provider.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TEMP fake data
    final programs = [
      {'name': 'Push Pull Legs', 'description': '3-day strength split'},
      {'name': 'Fat Loss', 'description': 'HIIT + cardio focused'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Programs')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.createProgram);
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];

          return ListTile(
            title: Text(program['name']!),
            subtitle: Text(program['description']!),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.push(
                '/program-details',
                extra: program,
              );
            },
          );
        },
      ),
    );
  }
}
