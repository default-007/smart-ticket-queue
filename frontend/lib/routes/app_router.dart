// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/models/agent.dart';
import 'package:smart_ticketing/models/ticket.dart';
import 'package:smart_ticketing/screens/agents/agent_form_screen.dart';
import 'package:smart_ticketing/screens/agents/agent_list_screen.dart';
import 'package:smart_ticketing/screens/auth/register_screen.dart';
import 'package:smart_ticketing/screens/profile/profile_screen.dart';
import 'package:smart_ticketing/screens/shifts/shift_management_screen.dart';
import 'package:smart_ticketing/screens/sla/sla_config_screen.dart';
import 'package:smart_ticketing/screens/sla/sla_dashboard_screen.dart';
import 'package:smart_ticketing/screens/tickets/create_ticket_screen.dart';
import 'package:smart_ticketing/screens/tickets/ticket_detail_screen.dart';
import 'package:smart_ticketing/screens/workload/workload_dashboard_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/agent_dashboard.dart';
import '../screens/tickets/ticket_list_screen.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthState _state;

  AuthStateNotifier(this._state) {
    print(
        'AuthStateNotifier created with state: ${_state.status}'); // Debug print
  }

  AuthState get state => _state;

  void update(AuthState newState) {
    print(
        'AuthStateNotifier updating state: ${newState.status}'); // Debug print
    _state = newState;
    notifyListeners();
  }
}

// Add authStateListenableProvider
final authStateListenableProvider = Provider<AuthStateNotifier>((ref) {
  final authState = ref.watch(authProvider);
  return AuthStateNotifier(authState);
});

// Update routerProvider
final routerProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ref.watch(authStateListenableProvider);

  return GoRouter(
    refreshListenable: authStateNotifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = authStateNotifier.state;
      final currentPath = state.uri.path;

      //debug print
      print(
          'Router redirect - Path: $currentPath, Auth Status: ${authState.status}');

      // Always allow access to splash screen during initial state
      if (authState.status == AuthStatus.initial && currentPath == '/splash') {
        return null;
      }

      // Direct navigation based on auth status
      switch (authState.status) {
        case AuthStatus.initial:
          return currentPath != '/splash' ? '/splash' : null;
        case AuthStatus.unauthenticated:
        case AuthStatus.error: // Handle error state same as unauthenticated
          if (currentPath == '/login' || currentPath == '/register') {
            return null;
          }
          return '/login';
        case AuthStatus.authenticated:
          // Redirect authenticated users away from auth screens
          if (currentPath == '/splash' ||
              currentPath == '/login' ||
              currentPath == '/register') {
            return _getInitialRoute(authState.user?.role);
          }

          return null;
        default:
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Dashboard Routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['admin'],
          child: AdminDashboard(),
        ),
      ),
      GoRoute(
        path: '/agent/dashboard',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['agent'],
          child: AgentDashboard(),
        ),
      ),
      // Ticket Routes
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['admin', 'agent', 'user'],
          child: TicketListScreen(),
        ),
      ),
      GoRoute(
        path: '/tickets/create',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['admin', 'agent', 'user'],
          child: CreateTicketScreen(),
        ),
      ),
      GoRoute(
        path: '/tickets/detail',
        builder: (context, state) {
          final ticket = state.extra as Ticket;
          return ProtectedRoute(
            allowedRoles: ['admin', 'agent', 'user'],
            child: TicketDetailScreen(ticket: ticket),
          );
        },
      ),
      // Admin Routes
      GoRoute(
        path: '/agents',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['admin'],
          child: AgentListScreen(),
        ),
      ),
      GoRoute(
        path: '/agents/create',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['admin'],
          child: AgentFormScreen(),
        ),
      ),
      GoRoute(
        path: '/agents/edit/:id',
        builder: (context, state) {
          final agent = state.extra as Agent;
          return ProtectedRoute(
            allowedRoles: ['admin'],
            child: AgentFormScreen(agent: agent),
          );
        },
      ),

      // Profile Route

      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['admin', 'agent', 'user'],
          child: ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/sla/dashboard',
        builder: (context, state) => const SLADashboardScreen(),
      ),
      GoRoute(
        path: '/sla/config',
        builder: (context, state) => const SLAConfigScreen(),
      ),
      // Workload Route
      GoRoute(
        path: '/workload',
        builder: (context, state) => const WorkloadDashboardScreen(),
      ),
      GoRoute(
        path: '/shifts',
        builder: (context, state) => const ShiftManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error?.toString() ?? 'Unknown error occurred',
    ),
  );
});

String _getInitialRoute(String? role) {
  switch (role) {
    case 'admin':
      return '/admin/dashboard';
    case 'agent':
      return '/agent/dashboard';
    default:
      return '/tickets';
  }
}

class ProtectedRoute extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;
  final bool adminOverride;

  const ProtectedRoute({
    Key? key,
    required this.child,
    required this.allowedRoles,
    this.adminOverride = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const LoadingScreen();
    }

    final userRole = authState.user?.role;

    // Admin override: if enabled, admins can access everything
    if (adminOverride && userRole == 'admin') {
      return child;
    }

    if (userRole == null || !allowedRoles.contains(userRole)) {
      return UnauthorizedScreen(
        onRedirect: () {
          final route = _getInitialRoute(userRole);
          GoRouter.of(context).go(route);
        },
      );
    }

    return child;
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  final VoidCallback onRedirect;

  const UnauthorizedScreen({
    Key? key,
    required this.onRedirect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRedirect,
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'An error occurred',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).refresh(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
