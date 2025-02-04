import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

class NavigationState {
  final String? route;

  NavigationState({this.route});

  NavigationState copyWith({String? route}) {
    return NavigationState(route: route ?? this.route);
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(NavigationState());

  void navigateBasedOnRole(User user) {
    if (user.role == 'admin') {
      state = state.copyWith(route: '/admin/dashboard');
    } else if (user.role == 'agent') {
      state = state.copyWith(route: '/agent/dashboard');
    } else {
      state = state.copyWith(route: '/tickets');
    }
  }

  void resetNavigation() {
    state = NavigationState();
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
  (ref) => NavigationNotifier(),
);
