import 'dart:async';
import 'package:llm_app/data/models/chat_message.dart';

/// Simple mock implementation of ChatRepository with in-memory storage
/// This will be replaced with a proper implementation using SQLite in the future
class ChatRepository {
  // In-memory storage for messages
  final List<ChatMessage> _messages = [];

  // Get all messages (simplified version)
  Future<List<ChatMessage>> getMessages() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_messages);
  }

  // Save a message to the repository
  Future<void> saveMessage(ChatMessage message) async {
    // Generate a random ID if not present
    if (message.id == null) {
      message.id = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Add to in-memory storage
    _messages.add(message);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    return;
  }

  // Delete all messages
  Future<void> clearMessages() async {
    _messages.clear();
    await Future.delayed(const Duration(milliseconds: 200));
    return;
  }

  // Get message count
  Future<int> getMessageCount() async {
    return _messages.length;
  }
}
