import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/shipment_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/locale_provider.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';
import 'screens/auth/splash_screen.dart';

class SwiftEgyptApp extends StatefulWidget {
  const SwiftEgyptApp({super.key});

  @override
  State<SwiftEgyptApp> createState() => _SwiftEgyptAppState();
}

class _SwiftEgyptAppState extends State<SwiftEgyptApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (ctx) {
            final api = ApiService();
            SyncService.setApi(api);
            return ShipmentProvider(api);
          },
        ),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              LocaleProvider(const FlutterSecureStorage())..loadLocale(),
        ),
      ],
      child: _AppConsumer(),
    );
  }
}

class _AppConsumer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final syncProv = context.watch<SyncProvider>();
    final shipmentProv = context.watch<ShipmentProvider>();

    if (auth.isAuthenticated && auth.token != null) {
      syncProv.connectWebSocket(auth.token!);
      syncProv.onWebSocketMessage = (msg) {
        shipmentProv.handleWebSocketMessage(msg);
      };
    }

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return MaterialApp(
          title: 'Swift Egypt',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(localeProvider.isDark),
          locale: Locale(localeProvider.locale),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
