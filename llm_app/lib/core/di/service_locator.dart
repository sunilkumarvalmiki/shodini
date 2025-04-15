import 'package:get_it/get_it.dart';
import 'package:llm_app/core/theme/theme_service.dart';

/// Service locator for dependency injection.
/// This provides a centralized registry for all services and dependencies
/// in the application, making them easily accessible throughout the app.
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services and dependencies for the application.
/// This should be called at app startup before the app is rendered.
Future<void> initServiceLocator() async {
  // Register services as Singletons

  // Register ThemeService
  serviceLocator.registerLazySingleton<ThemeService>(() => ThemeService());

  // Initialize services that require async initialization
  final themeService = serviceLocator<ThemeService>();
  await themeService.init();

  // Register repositories
  // TODO: Add repositories here when implemented

  // Register BLoCs
  // TODO: Add BLoCs here when implemented
}
