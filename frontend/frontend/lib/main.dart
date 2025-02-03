import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_ticketing/models/ticket.dart';
import 'package:smart_ticketing/models/user.dart';
import 'package:smart_ticketing/providers/auth_provider.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/agent_dashboard.dart';
import 'screens/tickets/ticket_list_screen.dart';
import 'screens/tickets/ticket_detail_screen.dart';
import 'screens/tickets/create_ticket_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
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
      initialRoute:
          authState.user != null ? _getInitialRoute(authState.user!) : '/login',
      onGenerateRoute: (settings) {
        if (authState.user == null &&
            settings.name != '/login' &&
            settings.name != '/register') {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          );
        }

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
            );
          case '/admin/dashboard':
            return MaterialPageRoute(
              builder: (_) => const AdminDashboard(),
            );
          case '/agent/dashboard':
            return MaterialPageRoute(
              builder: (_) => const AgentDashboard(),
            );
          case '/tickets':
            return MaterialPageRoute(
              builder: (_) => const TicketListScreen(),
            );
          case '/tickets/create':
            return MaterialPageRoute(
              builder: (_) => const CreateTicketScreen(),
            );
          case '/tickets/detail':
            final ticket = settings.arguments as Ticket;
            return MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: ticket),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text('Page not found'),
                ),
              ),
            );
        }
      },
    );
  }

  String _getInitialRoute(User user) {
    switch (user.role) {
      case 'admin':
        return '/admin/dashboard';
      case 'agent':
        return '/agent/dashboard';
      default:
        return '/tickets';
    }
  }
}
