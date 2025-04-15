import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Top-level routes
const String kSplashRoute = '/';
const String kHomeRoute = '/home';
const String kChatRoute = '/chat';
const String kProfileRoute = '/profile';
const String kDocsRoute = '/docs';
const String kMarketplaceRoute = '/marketplace';
const String kChatDetailRoute = '/chat/:chatId';

/// Application router configuration implementing GoRouter
/// for advanced navigation features including deep linking
/// and route parameter handling
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Get the router configuration
  static GoRouter get router => _router;

  /// Private GoRouter instance with all the route configurations
  static final GoRouter _router = GoRouter(
    initialLocation: kSplashRoute,
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics:
        true, // Useful for debugging, can be removed in production
    routes: [
      // Splash screen route
      GoRoute(
        path: kSplashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Shell route for bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomePage(child: child);
        },
        routes: [
          // Chat tab route
          GoRoute(
            path: kHomeRoute,
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ChatTab(),
            ),
            routes: [
              // Individual chat detail route with parameter
              GoRoute(
                path: 'chat/:chatId',
                name: 'chatDetail',
                builder: (context, state) {
                  final chatId = state.pathParameters['chatId']!;
                  return ChatDetailScreen(chatId: chatId);
                },
              ),
            ],
          ),

          // Docs tab route
          GoRoute(
            path: kDocsRoute,
            name: 'docs',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const DocsTab(),
            ),
          ),

          // Marketplace tab route
          GoRoute(
            path: kMarketplaceRoute,
            name: 'marketplace',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const MarketplaceTab(),
            ),
          ),

          // Profile tab route
          GoRoute(
            path: kProfileRoute,
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ProfileTab(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
}

// Using placeholder classes for now - these will be replaced by actual implementations
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation will be replaced with actual splash screen
    return const Scaffold(body: Center(child: Text('Splash Screen')));
  }
}

class HomePage extends StatelessWidget {
  final Widget child;

  const HomePage({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation will be replaced with actual home page
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Docs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Marketplace'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith(kHomeRoute)) return 0;
    if (location.startsWith(kDocsRoute)) return 1;
    if (location.startsWith(kMarketplaceRoute)) return 2;
    if (location.startsWith(kProfileRoute)) return 3;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(kHomeRoute);
        break;
      case 1:
        context.go(kDocsRoute);
        break;
      case 2:
        context.go(kMarketplaceRoute);
        break;
      case 3:
        context.go(kProfileRoute);
        break;
    }
  }
}

class ChatTab extends StatelessWidget {
  const ChatTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation will be replaced with actual chat tab
    return const Scaffold(body: Center(child: Text('Chat Tab')));
  }
}

class DocsTab extends StatelessWidget {
  const DocsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation will be replaced with actual docs tab
    return const Scaffold(body: Center(child: Text('Docs Tab')));
  }
}

class MarketplaceTab extends StatelessWidget {
  const MarketplaceTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation will be replaced with actual marketplace tab
    return const Scaffold(body: Center(child: Text('Marketplace Tab')));
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation will be replaced with actual profile tab
    return const Scaffold(body: Center(child: Text('Profile Tab')));
  }
}

class ChatDetailScreen extends StatelessWidget {
  final String chatId;

  const ChatDetailScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation will be replaced with actual chat detail screen
    return Scaffold(body: Center(child: Text('Chat Detail: $chatId')));
  }
}

class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({Key? key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Something went wrong!'),
            if (error != null) Text(error.toString()),
            ElevatedButton(
              onPressed: () => context.go(kHomeRoute),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
