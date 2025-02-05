import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ticketing/providers/auth_provider.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? ''),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(user?.name[0] ?? ''),
            ),
          ),
          // Dashboard based on user role
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              context.go(user?.role == 'admin'
                  ? '/admin/dashboard'
                  : user?.role == 'agent'
                      ? '/agent/dashboard'
                      : '/tickets');
            },
          ),
          // Tickets for all authenticated users
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Tickets'),
            onTap: () => context.go('/tickets'),
          ),
          // Create Ticket
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Create Ticket'),
            onTap: () => context.go('/tickets/create'),
          ),
          // Admin-specific routes
          if (user?.role == 'admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Agents'),
              onTap: () => context.go('/agents'),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('SLA Dashboard'),
              onTap: () => context.go('/sla/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('SLA Configuration'),
              onTap: () => context.go('/sla/config'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Workload Dashboard'),
              onTap: () => context.go('/workload'),
            ),
          ],
          // Profile for all authenticated users
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => context.go('/profile'),
          ),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
