import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/todo_task.dart';
import '../../core/state/app_state.dart';

class TodoBoardPage extends StatelessWidget {
  const TodoBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('New To-do')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _scoreBox('Completed', appState.completedCount, Colors.green),
                _scoreBox(
                  'In progress',
                  appState.inProgressCount,
                  Colors.amber,
                ),
                _scoreBox(
                  'Not completed',
                  appState.notCompletedCount,
                  Colors.redAccent,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: appState.healthScore / 100,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Health Score: ${appState.healthScore}/100'),
          ),
          Expanded(
            child: Row(
              children: [
                _buildColumn(
                  context,
                  'Not Completed',
                  TaskStatus.notCompleted,
                  Colors.redAccent,
                ),
                _buildColumn(
                  context,
                  'In Progress',
                  TaskStatus.inProgress,
                  Colors.amber,
                ),
                _buildColumn(
                  context,
                  'Completed',
                  TaskStatus.completed,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String title, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String title,
    TaskStatus status,
    Color color,
  ) {
    final tasks = context.watch<AppState>().byStatus(status);

    return Expanded(
      child: DragTarget<TodoTask>(
        onAcceptWithDetails: (details) {
          context.read<AppState>().setTaskStatus(details.data.id, status);
        },
        builder: (context, _, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Draggable<TodoTask>(
                        data: task,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _taskTile(
                            context,
                            task,
                            color.withValues(alpha: 0.9),
                            false,
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _taskTile(context, task, Colors.white, true),
                        ),
                        child: _taskTile(context, task, Colors.white, true),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _taskTile(
    BuildContext context,
    TodoTask task,
    Color bg,
    bool showActions,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCD4EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${task.subject} • ${task.type}'),
          Text(DateFormat('d MMM, h:mm a').format(task.dateTime)),
          if (showActions) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  onPressed: () => context.read<AppState>().setTaskStatus(
                        task.id,
                        TaskStatus.completed,
                      ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  tooltip: 'Mark completed',
                ),
                IconButton(
                  onPressed: () => context.read<AppState>().setTaskStatus(
                        task.id,
                        TaskStatus.inProgress,
                      ),
                  icon: const Icon(Icons.timelapse, color: Colors.amber),
                  tooltip: 'Mark in progress',
                ),
                IconButton(
                  onPressed: () => context.read<AppState>().setTaskStatus(
                        task.id,
                        TaskStatus.notCompleted,
                      ),
                  icon: const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Mark not completed',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    String type = 'Assignment';
    DateTime selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                      ),
                    ),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: 'Subject'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(
                          value: 'Assignment',
                          child: Text('Assignment'),
                        ),
                        DropdownMenuItem(
                          value: 'Subject To-Do',
                          child: Text('Subject To-Do'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            type = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date and time'),
                      subtitle: Text(
                        DateFormat('d MMM yyyy, h:mm a').format(selectedDate),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 3),
                            ),
                            initialDate: selectedDate,
                          );
                          if (date == null || !context.mounted) {
                            return;
                          }
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      return;
                    }
                    context.read<AppState>().addTask(
                          title: title,
                          subject: subjectController.text.trim().isEmpty
                              ? 'General'
                              : subjectController.text.trim(),
                          type: type,
                          dateTime: selectedDate,
                        );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
