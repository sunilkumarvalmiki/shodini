import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class ChatMessage {
  String? id;
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  List<AttachedFile>? attachedFiles;

  // Add cache flag to indicate if this message has been fully loaded
  bool _fullyLoaded = false;
  bool get isFullyLoaded => _fullyLoaded;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.attachedFiles,
  });

  // Create a ChatMessage from a Map (for database operations)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    List<AttachedFile> files = [];
    if (map.containsKey('attachedFiles')) {
      for (var fileMap in map['attachedFiles']) {
        files.add(AttachedFile.fromMap(fileMap));
      }
    }

    return ChatMessage(
      id: map['id'],
      text: map['text'],
      isUserMessage: map['is_user_message'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      attachedFiles: files.isNotEmpty ? files : null,
    );
  }

  // Convert a ChatMessage to a Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'is_user_message': isUserMessage ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Clone a message with or without deep-copying attachments
  ChatMessage clone({bool deepCopyAttachments = false}) {
    return ChatMessage(
      id: id,
      text: text,
      isUserMessage: isUserMessage,
      timestamp: timestamp,
      attachedFiles: attachedFiles == null
          ? null
          : deepCopyAttachments
              ? attachedFiles!.map((file) => file.clone()).toList()
              : List.from(attachedFiles!),
    );
  }

  // Clear any memory-heavy byte data from attachments
  void clearAttachmentBytes() {
    if (attachedFiles != null) {
      for (final file in attachedFiles!) {
        file.clearBytes();
      }
    }
  }

  // Mark message as fully loaded (e.g., all attachments loaded)
  void markAsFullyLoaded() {
    _fullyLoaded = true;
  }

  // Release memory when message scrolls out of view
  void releaseMemory() {
    clearAttachmentBytes();
    _fullyLoaded = false;
  }

  // Prepare message for display (lazy load attachments)
  Future<void> prepareForDisplay() async {
    if (_fullyLoaded || attachedFiles == null) return;

    // Load only essential data for display
    // Full bytes will be loaded on demand when visible
    _fullyLoaded = true;
  }
}

class AttachedFile {
  String? id;
  String? messageId;
  final String name;
  final String path;
  final int size;
  final String type;
  Uint8List? bytes;

  // Track loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Flag to indicate if bytes have been loaded
  bool get hasLoadedBytes => bytes != null;

  AttachedFile({
    this.id,
    this.messageId,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    this.bytes,
  });

  // Create an AttachedFile from a Map (for database operations)
  factory AttachedFile.fromMap(Map<String, dynamic> map) {
    Uint8List? fileBytes;
    if (map['bytes'] != null) {
      if (map['bytes'] is Uint8List) {
        fileBytes = map['bytes'];
      } else if (map['bytes'] is String) {
        try {
          fileBytes = Uint8List.fromList(base64Decode(map['bytes']));
        } catch (e) {
          print('Error decoding file bytes: $e');
        }
      }
    }

    return AttachedFile(
      id: map['id'],
      messageId: map['message_id'],
      name: map['name'],
      path: map['path'] ?? '',
      size: map['size'],
      type: map['type'],
      bytes: fileBytes,
    );
  }

  // Convert an AttachedFile to a Map (for database operations)
  Map<String, dynamic> toMap() {
    String? encodedBytes;
    if (bytes != null) {
      // For web, always encode bytes
      // For native, only encode if file path is not available
      if (kIsWeb || path.isEmpty) {
        try {
          encodedBytes = base64Encode(bytes!);
        } catch (e) {
          print('Error encoding file bytes: $e');
        }
      }
    }

    return {
      'id': id,
      'message_id': messageId,
      'name': name,
      'path': path,
      'size': size,
      'type': type,
      'bytes': encodedBytes,
    };
  }

  // Clone this file, optionally without copying memory-intensive bytes
  AttachedFile clone({bool copyBytes = true}) {
    return AttachedFile(
      id: id,
      messageId: messageId,
      name: name,
      path: path,
      size: size,
      type: type,
      bytes: copyBytes
          ? (bytes != null ? Uint8List.fromList(bytes!) : null)
          : null,
    );
  }

  // Clear bytes to free up memory
  void clearBytes() {
    bytes = null;
  }

  // Load bytes from storage on demand
  Future<void> loadBytes() async {
    if (bytes != null || _isLoading || path.isEmpty) return;

    _isLoading = true;
    try {
      if (!kIsWeb && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          // Use compute to move loading to background
          bytes = await File(path).readAsBytes();
        }
      }
    } catch (e) {
      print('Error loading file bytes: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Check if this is an image file
  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif'].contains(type.toLowerCase());

  // Check if this is a text file
  bool get isText => ['txt', 'md', 'json', 'csv'].contains(type.toLowerCase());

  // Get file extension
  String get extension => type.toLowerCase();
}
