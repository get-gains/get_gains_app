import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/program_service.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key, this.programId});

  final String? programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (programId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Calendar')),
        body: const Center(child: Text('No program selected')),
      );
    }

    final routinesAsyncValue = ref.watch(programRoutinesProvider(programId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Calendar')),
      body: routinesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        data: (routines) => routines.isEmpty
            ? const Center(child: Text('No routines scheduled'))
            : ListView.separated(
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(routine['day'] ?? 'Unnamed'),
                    subtitle: Text(routine['name'] ?? 'No routine'),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              ),
      ),
    );
  }
}

