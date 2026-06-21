import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../core/theme.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _sortBy = 'time';
  String _filterBy = 'all';

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    var tasks = taskProvider.tasks;

    if (_filterBy == 'pending') {
      tasks = taskProvider.pendingTasks;
    } else if (_filterBy == 'in_progress') {
      tasks = taskProvider.inProgressTasks;
    } else if (_filterBy == 'completed') {
      tasks = taskProvider.completedTasks;
    }

    if (_sortBy == 'priority') {
      tasks = List.from(tasks)
        ..sort((a, b) => b.estimatedPrice?.compareTo(a.estimatedPrice ?? 0) ?? 0);
    } else {
      tasks = List.from(tasks)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام اليومية'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filterBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('الكل'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('معلقة'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('قيد التنفيذ'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('مكتملة'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'time',
                child: Text('حسب الوقت'),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Text('حسب الأولوية'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => taskProvider.loadTodayTasks(),
        child: taskProvider.isLoading && tasks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : tasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tasks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Text(
                            '${tasks.length} مهمة',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        );
                      }
                      final task = tasks[index - 1];
                      return TaskCard(
                        shipment: task,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/task/detail',
                            arguments: task.id,
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مهام اليوم',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض مهامك هنا عند توفرها',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
