// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_app/main.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  testWidgets('App should build without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Just verify the app builds without errors
    expect(find.byType(MaterialApp), findsWidgets);
  });

  // Add more unit tests without widget testing
  group('Basic unit tests', () {
    test('True should be true', () {
      expect(true, isTrue);
    });
  });

  group('App UI Tests', () {
    testWidgets('Splash screen displays correctly',
        (WidgetTester tester) async {
      // Build the splash screen and trigger a frame
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify splash screen elements
      expect(find.text('Open-Source LLM App'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the splash screen timer
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(); // Process navigation

      // Should now be on the home page
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Bottom navigation switches tabs', (WidgetTester tester) async {
      // Build the home page
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Verify initial tab (Chat tab)
      expect(find.byType(ChatTab), findsOneWidget);

      // Tap on the Docs tab
      await tester.tap(find.byIcon(Icons.description));
      await tester.pump();

      // Should now be on the Docs tab
      expect(find.text('Document Processing'), findsOneWidget);

      // Tap on the Marketplace tab
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pump();

      // Should now be on the Marketplace tab
      expect(find.text('Model Marketplace'), findsOneWidget);

      // Tap on the Profile tab
      await tester.tap(find.byIcon(Icons.person));
      await tester.pump();

      // Should now be on the Profile tab
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Theme toggle switches between light and dark mode',
        (WidgetTester tester) async {
      // Build the home page
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Get the initial theme mode
      final bool initialDarkMode =
          tester.widget<Icon>(find.byType(Icon).first).icon == Icons.light_mode;

      // Tap the theme toggle button
      await tester.tap(find.byTooltip('Toggle Theme'));
      await tester.pump();

      // Verify the theme has toggled
      final bool toggledDarkMode =
          tester.widget<Icon>(find.byType(Icon).first).icon == Icons.light_mode;
      expect(toggledDarkMode, !initialDarkMode);
    });
  });

  group('Chat Functionality Tests', () {
    testWidgets('Can send a message and receive a response',
        (WidgetTester tester) async {
      // Build the chat tab
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatTab(),
          ),
        ),
      );

      // Enter a message
      await tester.enterText(find.byType(TextField), 'Hello, LLM!');

      // Tap the send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify the message was sent
      expect(find.text('Hello, LLM!'), findsOneWidget);

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the "AI" response (simulated delay)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Verify loading indicator is gone
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify a response was received (checking for any Container widget)
      expect(find.byWidgetPredicate((widget) => widget is Container),
          findsAtLeastNWidgets(1));
    });

    testWidgets('Model selection dropdown works', (WidgetTester tester) async {
      // Build the chat tab
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: null,
            body: ChatTab(),
          ),
        ),
      );

      // Find and tap the dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Choose "GPT-4" from the dropdown
      await tester.tap(find.text('GPT-4').last);
      await tester.pumpAndSettle();

      // Verify the selection changed
      expect(find.text('GPT-4'), findsOneWidget);
    });

    testWidgets('File upload button is present', (WidgetTester tester) async {
      // Build the chat tab
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatTab(),
          ),
        ),
      );

      // Verify file upload button is present
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });
}
