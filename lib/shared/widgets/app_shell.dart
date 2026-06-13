import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = switch (location) {
      final value when value.startsWith('/sessions') => 1,
      final value when value.startsWith('/settings') => 2,
      _ => 0,
    };

    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _go(context, index),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.fiber_manual_record_outlined),
                  selectedIcon: Icon(Icons.fiber_manual_record),
                  label: Text('录制'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: Text('会话'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('设置'),
                ),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _go(context, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.fiber_manual_record_outlined),
                  selectedIcon: Icon(Icons.fiber_manual_record),
                  label: '录制',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: '会话',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: '设置',
                ),
              ],
            )
          : null,
    );
  }

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/record');
      case 1:
        context.go('/sessions');
      case 2:
        context.go('/settings');
    }
  }
}
