import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/shipments/create_shipment_screen.dart';
import '../screens/shipments/shipment_list_screen.dart';
import '../screens/shipments/shipment_detail_screen.dart';
import '../screens/shipments/shipment_tracking_screen.dart';
import '../screens/shipments/pricing_calculator_screen.dart';
import '../screens/documents/documents_screen.dart';
import '../screens/payments/invoices_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/support/chat_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createShipment = '/create-shipment';
  static const String shipments = '/shipments';
  static const String shipmentDetail = '/shipment-detail';
  static const String tracking = '/tracking';
  static const String pricing = '/pricing';
  static const String documents = '/documents';
  static const String invoices = '/invoices';
  static const String support = '/support';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case createShipment:
        return _buildRoute(
          CreateShipmentScreen(serviceType: args as int?),
          settings,
        );
      case shipments:
        return _buildRoute(const ShipmentListScreen(), settings);
      case shipmentDetail:
        return _buildRoute(
          ShipmentDetailScreen(shipmentId: args as String),
          settings,
        );
      case tracking:
        return _buildRoute(
          ShipmentTrackingScreen(shipmentId: args as String),
          settings,
        );
      case pricing:
        return _buildRoute(const PricingCalculatorScreen(), settings);
      case documents:
        return _buildRoute(
          DocumentsScreen(shipmentId: args as String?),
          settings,
        );
      case invoices:
        return _buildRoute(const InvoicesScreen(), settings);
      case support:
        return _buildRoute(const SupportScreen(), settings);
      case chat:
        return _buildRoute(const ChatScreen(), settings);
      case notifications:
        return _buildRoute(const NotificationsScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
