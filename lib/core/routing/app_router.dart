import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/playback/presentation/playback_page.dart';
import '../../features/recorder/presentation/recorder_page.dart';
import '../../features/sessions/presentation/import_session_page.dart';
import '../../features/sessions/presentation/sessions_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/record',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/record',
            name: 'record',
            builder: (context, state) => const RecorderPage(),
          ),
          GoRoute(
            path: '/sessions',
            name: 'sessions',
            builder: (context, state) => const SessionsPage(),
            routes: [
              GoRoute(
                path: 'import',
                name: 'import-session',
                builder: (context, state) => const ImportSessionPage(),
              ),
              GoRoute(
                path: ':sessionId',
                name: 'playback',
                builder: (context, state) => PlaybackPage(
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
