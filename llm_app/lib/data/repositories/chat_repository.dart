import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class ChatRepository {
  final _databaseHelper = DatabaseHelper();

  // Get count of messages for batched loading
  Future<int> getMessageCount() async {
    try {
      final db = await _databaseHelper.database;
      final result =
          await db.rawQuery('SELECT COUNT(*) as count FROM messages');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting message count: $e');
      return 0;
    }
  }

  // Get a batch of messages for efficient loading
  Future<List<ChatMessage>> getMessageBatch(int offset, int limit) async {
    try {
      final db = await _databaseHelper.database;

      // Query messages with pagination
      final messagesList = await db.query(
        'messages',
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      if (messagesList.isEmpty) {
        return [];
      }

      // Use compute for processing large datasets
      final messages = await compute(_parseMessages, messagesList);

      // Get message IDs for batch loading attachments
      final messageIds = messages.map((m) => m.id!).toList();

      // Get attachments for these messages
      if (messageIds.isNotEmpty) {
        final attachmentsList = await db.query(
          'attachments',
          where:
              'message_id IN (${List.filled(messageIds.length, '?').join(',')})',
          whereArgs: messageIds,
        );

        if (attachmentsList.isNotEmpty) {
          final attachments = await compute(_parseAttachments, attachmentsList);
          _addAttachmentsToMessages(messages, attachments);
        }
      }

      return messages;
    } catch (e) {
      print('Error getting message batch: $e');
      return [];
    }
  }

  void _addAttachmentsToMessages(
      List<ChatMessage> messages, List<Attachment> attachments) {
    // Implementation of _addAttachmentsToMessages method
  }

  List<ChatMessage> _parseMessages(List<Map<String, dynamic>> messagesList) {
    // Implementation of _parseMessages method
    return [];
  }

  List<Attachment> _parseAttachments(
      List<Map<String, dynamic>> attachmentsList) {
    // Implementation of _parseAttachments method
    return [];
  }
}
