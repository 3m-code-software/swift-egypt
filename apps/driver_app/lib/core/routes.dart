import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/tasks/task_navigation_screen.dart';
import '../screens/delivery/status_update_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/activity/activity_log_screen.dart';
import '../screens/ai/ai_chat_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String taskList = '/tasks';
  static const String taskDetail = '/task/detail';
  static const String taskNavigation = '/task/navigation';

  static const String profile = '/profile';
  static const String activityLog = '/activity';
  static const String aiChat = '/ai-chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case taskList:
        return MaterialPageRoute(builder: (_) => const TaskListScreen());
      case taskDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TaskDetailScreen(orderId: orderId),
        );
      case taskNavigation:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TaskNavigationScreen(
            pickupLat: args['pickupLat'] as double,
            pickupLng: args['pickupLng'] as double,
            deliveryLat: args['deliveryLat'] as double,
            deliveryLng: args['deliveryLng'] as double,
            destinationName: args['destinationName'] as String,
            recipientPhone: args['recipientPhone'] as String?,
          ),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case activityLog:
        return MaterialPageRoute(builder: (_) => const ActivityLogScreen());
      case aiChat:
        return MaterialPageRoute(builder: (_) => const AiChatScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
