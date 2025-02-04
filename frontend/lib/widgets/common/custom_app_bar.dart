import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        if (actions != null) ...actions!,
        IconButton(
          icon: CircleAvatar(
            radius: 14,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
