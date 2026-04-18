import 'package:flutter/material.dart';
import '../../services/task_notification_service.dart';
import '../../theme/app_theme.dart';
import '../tasks/task_detail_screen.dart';
import '../../models/task_model.dart';

class NotificationsScreen extends StatefulWidget {
  final Function(Task)? onTaskUpdated;

  const NotificationsScreen({
    super.key,
    this.onTaskUpdated,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  final Map<int, bool> _expandedNotifications = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.refreshTaskNotifications();
      await _notificationService.cleanUpCompletedTaskNotifications();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showSnackBar(
          'Error loading notifications: $e',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          _buildAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
          _buildAppBarAction(
            icon: Icons.checklist_rounded,
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Alerts'),
                Tab(text: 'Updates'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : ValueListenableBuilder<List<NotificationItem>>(
        valueListenable: _notificationService.notificationsNotifier,
        builder: (context, notifications, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationsList(notifications, 'all'),
              _buildNotificationsList(
                notifications.where((n) => n.type == 'alert').toList(),
                'alerts',
              ),
              _buildNotificationsList(
                notifications.where((n) => n.type == 'update').toList(),
                'updates',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 22,
        color: AppTheme.primaryColor,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications, String type) {
    if (notifications.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      backgroundColor: Colors.white,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    final Map<String, Map<String, dynamic>> emptyStateData = {
      'all': {
        'icon': Icons.notifications_off_rounded,
        'title': 'No Notifications',
        'subtitle': 'You\'re all caught up! Check back later for new updates.',
      },
      'alerts': {
        'icon': Icons.warning_amber_rounded,
        'title': 'No Alerts',
        'subtitle': 'No urgent alerts at the moment.',
      },
      'updates': {
        'icon': Icons.info_outline_rounded,
        'title': 'No Updates',
        'subtitle': 'No new updates available right now.',
      },
    };

    final data = emptyStateData[type] ?? emptyStateData['all']!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                data['icon'] as IconData,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              data['title'] as String,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (type != 'all')
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Refresh'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final isExpanded = _expandedNotifications[notification.id] ?? false;
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Dismissible(
      key: Key(notification.id.toString()),
      background: _buildDismissBackground(),
      secondaryBackground: _buildDismissBackground(isSecondary: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(notification);
        }
        return false;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _notificationService.removeNotification(notification.id);
          _showSnackBar('Notification removed');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: notification.isRead ? Colors.transparent : color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleNotificationTap(notification),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: notification.isRead ?
                                      Colors.grey.shade600 : Colors.black,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.time,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isExpanded ?
                          Icons.expand_less_rounded :
                          Icons.expand_more_rounded,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          setState(() {
                            _expandedNotifications[notification.id] = !isExpanded;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Divider(
                      color: Colors.grey.shade200,
                      height: 1,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    if (notification.task != null) ...[
                      const SizedBox(height: 12),
                      _buildTaskPreview(notification.task!),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground({bool isSecondary = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isSecondary ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildTaskPreview(Task task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due: ${task.dueDate}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Option: Show priority badge instead
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: task.priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.priorityText.toUpperCase(),
              style: TextStyle(
                color: task.priorityColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(NotificationItem notification) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete "${notification.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    // Mark as read
    await _notificationService.markAsRead(notification.id);

    // Handle notification based on task
    if (notification.task != null) {
      _navigateToTaskDetail(notification.task!);
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    _showSnackBar('All notifications marked as read');
  }

  void _navigateToTaskDetail(Task task) async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          onTaskUpdated: (Task updated) {
            widget.onTaskUpdated?.call(updated);
            _loadNotifications();
          },
        ),
      ),
    );

    if (updatedTask != null) {
      _loadNotifications();
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'alert':
        return Colors.red;
      case 'update':
        return AppTheme.primaryColor;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'update':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getTaskStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}