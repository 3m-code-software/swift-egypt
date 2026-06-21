import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/task_provider.dart';
import '../../widgets/status_badge.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<BatchOrder> _completedTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final provider = context.read<TaskProvider>();
    if (mounted) {
      setState(() {
        _completedTasks = provider.completedTasks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النشاط'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildActivityCard(task);
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
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد مهام مكتملة',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر المهام المكتملة هنا',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BatchOrder order) {
    final isDelivered = order.status == OrderStatus.delivered;
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/task/detail', arguments: order.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isDelivered
                          ? AppTheme.accentGreen
                          : Colors.grey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDelivered
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: isDelivered ? AppTheme.accentGreen : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusBadge(status: order.status, small: true),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MM/dd HH:mm').format(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.total.toStringAsFixed(0)} ج.م',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.accentGreen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
