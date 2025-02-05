import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class RouteGuard extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;
  final Widget Function(BuildContext)? onUnauthorized;

  const RouteGuard({
    Key? key,
    required this.child,
    required this.allowedRoles,
    this.onUnauthorized,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authState.isAuthenticated) {
      return onUnauthorized?.call(context) ?? const LoginScreen();
    }

    final userRole = authState.user?.role;
    if (userRole == null || !allowedRoles.contains(userRole)) {
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
                onPressed: () => Navigator.of(context).pushReplacementNamed(
                  _getInitialRoute(userRole),
                ),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }

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
}
