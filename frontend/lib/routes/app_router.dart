// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/models/ticket.dart';
import 'package:smart_ticketing/screens/profile/profile_screen.dart';
import 'package:smart_ticketing/screens/tickets/create_ticket_screen.dart';
import 'package:smart_ticketing/screens/tickets/ticket_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/agent_dashboard.dart';
import '../screens/tickets/ticket_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final authState = ref.watch(authProvider);

  return GoRouter(
    refreshListenable: ValueNotifier<AuthState>(authState),
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';

      // Handle initial state
      if (authState.status == AuthStatus.initial) {
        return '/splash';
      }

      // Handle unauthenticated state
      if (authState.status == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // Handle authenticated state
      if (authState.status == AuthStatus.authenticated) {
        if (isLoggingIn) {
          return _getInitialRoute(authState.user?.role);
        }

        // Role-based route protection
        final userRole = authState.user?.role;
        final currentPath = state.uri.path;

        if (currentPath.startsWith('/admin') && userRole != 'admin') {
          return _getInitialRoute(userRole);
        }

        if (currentPath.startsWith('/agent') && userRole != 'agent') {
          return _getInitialRoute(userRole);
        }
      }

      return null;
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
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProtectedRoute(
          allowedRoles: ['admin', 'agent', 'user'],
          child: ProfileScreen(),
        ),
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

  const ProtectedRoute({
    Key? key,
    required this.child,
    required this.allowedRoles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const LoadingScreen();
    }

    final userRole = authState.user?.role;
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
