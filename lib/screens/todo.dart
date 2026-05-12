import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import '../providers/auth_provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../widgets/app_logo.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  String _getDayName(int day) {
    const days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[day];
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAddTaskSheet() {
    final controller = TextEditingController();
    String selectedFrequency = 'once';
    int selectedDay = DateTime.now().weekday;
    bool isRepeating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return StatefulBuilder( // ✅ Necessary to update UI inside the sheet
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: screenHeight * 0.45, // Slightly taller to fit options
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'Brain dump your task...'),
                        autofocus: true,
                      ),
                      const SizedBox(height: 10),
                      
                      // ✅ Repeat Toggle
                      CheckboxListTile(
                        title: const Text("Repeat Task"),
                        value: isRepeating,
                        onChanged: (val) => setSheetState(() => isRepeating = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      // ✅ Sub-options for Repeating
                      if (isRepeating) ...[
                        Row(
                          children: [
                            const Text("Frequency: "),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: selectedFrequency == 'once' ? 'daily' : selectedFrequency,
                              items: const [
                                DropdownMenuItem(value: 'daily', child: Text("Daily")),
                                DropdownMenuItem(value: 'weekly', child: Text("Weekly")),
                              ],
                              onChanged: (val) => setSheetState(() {
                                selectedFrequency = val!;
                              }),
                            ),
                          ],
                        ),
                        if (selectedFrequency == 'weekly')
                          DropdownButton<int>(
                            value: selectedDay,
                            isExpanded: true,
                            items: List.generate(7, (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text("Every ${_getDayName(index + 1)}"),
                            )),
                            onChanged: (val) => setSheetState(() => selectedDay = val!),
                          ),
                      ],

                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.20,
                            vertical: 15,
                          ),
                        ),
                        onPressed: () {
                          final taskText = controller.text.trim();
                          if (taskText.isEmpty) {
                            showTopSnackBar(Overlay.of(context), const CustomSnackBar.error(message: "Empty thought!"));
                            return;
                          }
                          
                          final currentLength = ref.read(todoStreamProvider).value?.length ?? 0;
                          
                          // Pass the new fields to your addTask function
                          ref.read(todoActionProvider).addTask(
                            taskText, 
                            currentLength,
                            frequency: isRepeating ? selectedFrequency : 'once',
                            repeatDay: (isRepeating && selectedFrequency == 'weekly') ? selectedDay : null,
                          );
                          
                          Navigator.pop(context);
                          _scrollToBottom();
                        },
                        child: const Text('Add Task'),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final todoAsync = ref.watch(todoStreamProvider);
    final int today = DateTime.now().weekday; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Dump'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'All Tasks'), Tab(text: 'Starred')],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Center(child: AppLogo())),
            ListTile(leading: const Icon(Icons.refresh), title: const Text('Refresh'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.done_all), title: const Text('Completed Tasks'), onTap: () => Navigator.pushNamed(context, '/completed')),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: todoAsync.when(
        data: (todos) {
          // Filter the list based on your rules
          final filteredTodos = todos.where((todo) {
            // Rule 1: Always show 'once' or 'daily' tasks
            if (todo.frequency != 'weekly') return true;

            // Rule 2: For 'weekly', only show if repeatDay matches today
            return todo.repeatDay == today;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTodoList(filteredTodos.where((t) => !t.isDone).toList()),
              _buildTodoList(filteredTodos.where((t) => t.isStarred && !t.isDone).toList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoList(List<Todo> list) {
    return ReorderableListView.builder(
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                elevation: 2, // ✅ Remove heavy shadow
                color: Colors.white.withValues(alpha: 0.2), // ✅ Make it slightly transparent
                child: child,
              );
            },
            child: child,
          );
        },
      scrollController: _scrollController,
      itemCount: list.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final List<Todo> items = List<Todo>.from(list); 
        final item = items.removeAt(oldIndex);
        items.insert(newIndex, item);

        ref.read(todoActionProvider).updatePositions(items);
      },
      itemBuilder: (context, index) {
        final todo = list[index];
        return Dismissible(
          key: Key(todo.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Task?'),
                content: const Text('Are you sure you want to remove this from your dump?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            // Talk to Firestore directly via your action provider
            await ref.read(todoActionProvider).deleteTodo(todo.id);

            if (!context.mounted) return;
            showTopSnackBar(
              Overlay.of(context),
              const CustomSnackBar.success(
                message: "Task removed from your dump",
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1), // ✅ Subtle grey line
              ),
            ),
            child: Center(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Checkbox(
                  value: todo.isDone,
                  onChanged: (_) => ref.read(todoActionProvider).toggleDone(todo),
                ),
                title: Text(todo.task),
                subtitle: todo.frequency == 'weekly' && todo.repeatDay != null
                  ? Text(
                      "Every ${_getDayName(todo.repeatDay!)}",
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    )
                  : (todo.frequency == 'daily' ? const Text("Repeats Daily") : null),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 35.0, left: 5.0),
                  child: IconButton(
                    constraints: const BoxConstraints(), // Removes default padding of IconButton
                    padding: EdgeInsets.zero, 
                    icon: Icon(
                      todo.isStarred ? Icons.star : Icons.star_border, 
                      color: todo.isStarred ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => ref.read(todoActionProvider).toggleStar(todo),
                  ),
                ),

              ),
            ),
          ),
        );
      },
    );
  
  }
}

