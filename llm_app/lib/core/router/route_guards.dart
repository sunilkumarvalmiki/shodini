import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route guard class that provides middleware functionality for
/// redirecting routes based on authentication state and other conditions
class RouteGuards {
  /// Authentication state check that redirects to login if not authenticated
  /// Returns the path to redirect to, or null if no redirection is needed
  static String? authGuard(BuildContext context, GoRouterState state) {
    // This would normally check an auth service or provider
    // Here we're using a simple check for demonstration
    const bool isAuthenticated = false; // Replace with actual auth check

    // List of routes that are allowed without authentication
    final List<String> publicRoutes = [
      '/', // Splash screen
      '/login', // Login page
      '/register', // Registration page
    ];

    // If user is not authenticated and trying to access a protected route
    if (!isAuthenticated && !publicRoutes.contains(state.matchedLocation)) {
      // Redirect to login, keeping the intended destination in the query params
      return '/login?from=${state.matchedLocation}';
    }

    // If user is authenticated and trying to access login/register/splash
    if (isAuthenticated && publicRoutes.contains(state.matchedLocation)) {
      // Redirect to the home screen or another authenticated landing page
      return '/home';
    }

    // No redirection needed
    return null;
  }

  /// Feature access guard that checks if a user has access to certain features
  /// This can be based on subscription level, permissions, etc.
  static String? featureGuard(BuildContext context, GoRouterState state) {
    // This would check if the user has access to certain features
    // For example, premium features may be locked for free users
    const bool hasPremiumAccess = false; // Replace with actual check

    // Define feature-restricted routes
    final List<String> premiumRoutes = [
      '/marketplace/premium',
      '/docs/advanced',
    ];

    // If user tries to access premium feature without access
    if (!hasPremiumAccess &&
        premiumRoutes.any((route) => state.matchedLocation.startsWith(route))) {
      // Redirect to upgrade page or show a message
      return '/subscription/upgrade?from=${state.matchedLocation}';
    }

    // No redirection needed
    return null;
  }

  /// Combines multiple route guards into a single redirect function
  /// Returns the first non-null redirect path from any guard
  static String? combineGuards(BuildContext context, GoRouterState state) {
    // Order matters here - auth check should typically come first
    return authGuard(context, state) ?? featureGuard(context, state);
  }
}
