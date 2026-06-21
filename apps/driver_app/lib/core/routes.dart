import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/tasks/task_navigation_screen.dart';
import '../screens/delivery/proof_of_delivery_screen.dart';
import '../screens/delivery/proof_of_pickup_screen.dart';
import '../screens/delivery/collection_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/activity/activity_log_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String taskList = '/tasks';
  static const String taskDetail = '/task/detail';
  static const String taskNavigation = '/task/navigation';
  static const String proofOfDelivery = '/delivery/proof';
  static const String proofOfPickup = '/pickup/proof';
  static const String collection = '/delivery/collection';
  static const String profile = '/profile';
  static const String activityLog = '/activity';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case taskList:
        return MaterialPageRoute(builder: (_) => const TaskListScreen());
      case taskDetail:
        final shipmentId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TaskDetailScreen(shipmentId: shipmentId),
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
      case proofOfDelivery:
        final shipmentId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProofOfDeliveryScreen(shipmentId: shipmentId),
        );
      case proofOfPickup:
        final shipmentId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProofOfPickupScreen(shipmentId: shipmentId),
        );
      case collection:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CollectionScreen(
            shipmentId: args['shipmentId'] as String,
            amount: args['amount'] as double,
          ),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case activityLog:
        return MaterialPageRoute(builder: (_) => const ActivityLogScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
