import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class CompletedTasksPage extends ConsumerWidget {
  const CompletedTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoStreamProvider);
    final actions = ref.read(todoActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Items'),
        actions: [
          TextButton(
            onPressed: () => _confirmDeleteAll(context, ref),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: todoAsync.when(
        data: (todos) {
          final completed = todos.where((t) => t.isDone).toList();
          
          if (completed.isEmpty) {
            return const Center(child: Text("No completed tasks yet."));
          }

          return ListView.builder(
            itemCount: completed.length,
            itemBuilder: (context, index) {
              final todo = completed[index];
              return ListTile(
                leading: Checkbox(
                  value: true,
                  onChanged: (_) => actions.toggleDone(todo), // Unticking reverts it
                ),
                title: Text(
                  todo.task,
                  style: const TextStyle(decoration: TextDecoration.lineThrough),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will permanently delete all finished tasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(todoActionProvider).deleteAllCompleted(); // New action needed
              Navigator.pop(ctx);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
