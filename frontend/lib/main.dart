import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ticketing/providers/auth_provider.dart';
import 'package:smart_ticketing/screens/agents/agent_list_screen.dart';
import 'package:smart_ticketing/services/api_service.dart';
import 'package:smart_ticketing/services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/agent_dashboard.dart';
import 'screens/tickets/ticket_list_screen.dart';
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
    final authState = ref.watch(authProvider);
    final navigationState = ref.watch(navigationProvider);

    // Listen to auth state changes
    ref.listen(authProvider, (previous, current) {
      if (current.user != null) {
        ref
            .read(navigationProvider.notifier)
            .navigateBasedOnRole(current.user!);
      }
    });

    // Determine initial route
    Widget initialScreen = const LoginScreen();
    if (authState.user != null) {
      switch (authState.user!.role) {
        case 'admin':
          initialScreen = const AdminDashboard();
          break;
        case 'agent':
          initialScreen = const AgentDashboard();
          break;
        default:
          initialScreen = const TicketListScreen();
      }
    }

    return MaterialApp(
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
      home: initialScreen,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin/dashboard': (context) => const AdminDashboard(),
        '/agent/dashboard': (context) => const AgentDashboard(),
        '/tickets': (context) => const TicketListScreen(),
        '/agents': (context) => const AgentListScreen(),
      },
      // Add navigation observer
      navigatorObservers: [
        NavigatorObserver(),
      ],
      // Handle navigation state changes
      onGenerateRoute: (settings) {
        if (navigationState.route != null) {
          final route = navigationState.route!;
          ref.read(navigationProvider.notifier).resetNavigation();
          return MaterialPageRoute(
            builder: (context) {
              switch (route) {
                case '/admin/dashboard':
                  return const AdminDashboard();
                case '/agent/dashboard':
                  return const AgentDashboard();
                case '/tickets':
                  return const TicketListScreen();
                default:
                  return const LoginScreen();
              }
            },
          );
        }
        return null;
      },
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
