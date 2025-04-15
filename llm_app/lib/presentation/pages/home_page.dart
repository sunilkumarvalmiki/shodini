import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:llm_app/core/router/app_router.dart';
import 'package:llm_app/core/theme/theme_service.dart';
import 'package:llm_app/core/di/service_locator.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final Widget child;

  const HomePage({Key? key, required this.child}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open-Source LLM App'),
        actions: [
          IconButton(
            icon: Icon(
                themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeService.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: child, // Display child widget from ShellRoute
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Docs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
