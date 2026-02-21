import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/router_provider.dart';
import '../../../services/program_service.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsyncValue = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Programs')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.createProgram);
        },
        child: const Icon(Icons.add),
      ),
      body: programsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        data: (programs) => ListView.builder(
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final program = programs[index];

            return ListTile(
              title: Text(program['name'] ?? 'Unnamed'),
              subtitle: Text(program['description'] ?? 'No description'),
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
      ),
    );
  }
}