import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ticketing/providers/auth_provider.dart';
import 'package:smart_ticketing/services/api_service.dart';
import 'package:smart_ticketing/services/auth_service.dart';
import 'controllers/navigation_controller.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test API connection
  final apiService = ApiService();
  final authService = AuthService(apiService);
  try {
    final isConnected = await authService.testConnection();
    print('API Connection Test: ${isConnected ? 'Success' : 'Failed'}');
  } catch (e) {
    print('API Connection Test Error: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Listen to auth state changes
    ref.listen(authProvider, (previous, current) {
      if (current.user != null) {
        ref
            .read(navigationProvider.notifier)
            .navigateBasedOnRole(current.user!);
      }
    });

    return MaterialApp.router(
      title: 'Smart Ticketing',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      routerConfig: router,
    );
  }

  /* String _getInitialRoute(User user) {
    switch (user.role) {
      case 'admin':
        return '/admin/dashboard';
      case 'agent':
        return '/agent/dashboard';
      default:
        return '/tickets';
    }
  } */
}
