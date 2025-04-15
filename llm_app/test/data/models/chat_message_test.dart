import 'package:flutter_test/flutter_test.dart';
import 'package:llm_app/data/models/chat_message.dart';
import 'dart:typed_data';

void main() {
  group('ChatMessage', () {
    test('should create a ChatMessage instance properly', () {
      // Arrange
      final DateTime now = DateTime.now();

      // Act
      final ChatMessage message = ChatMessage(
        text: 'Hello, world!',
        isUserMessage: true,
        timestamp: now,
      );

      // Assert
      expect(message.text, 'Hello, world!');
      expect(message.isUserMessage, true);
      expect(message.timestamp, now);
      expect(message.attachedFiles, null);
    });

    test('should create a ChatMessage with attached files', () {
      // Arrange
      final DateTime now = DateTime.now();
      final List<AttachedFile> files = [
        AttachedFile(
          name: 'test.txt',
          path: '/path/to/test.txt',
          size: 4,
          type: 'txt',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        )
      ];

      // Act
      final ChatMessage message = ChatMessage(
        text: 'Check this file',
        isUserMessage: true,
        timestamp: now,
        attachedFiles: files,
      );

      // Assert
      expect(message.text, 'Check this file');
      expect(message.isUserMessage, true);
      expect(message.timestamp, now);
      expect(message.attachedFiles, isNotNull);
      expect(message.attachedFiles!.length, 1);
      expect(message.attachedFiles![0].name, 'test.txt');
      expect(message.attachedFiles![0].path, '/path/to/test.txt');
      expect(message.attachedFiles![0].type, 'txt');
      expect(message.attachedFiles![0].isText, true);
    });

    test('should convert to and from Map correctly', () {
      // Arrange
      final DateTime now = DateTime.now();
      final ChatMessage message = ChatMessage(
        id: '123',
        text: 'Hello, world!',
        isUserMessage: true,
        timestamp: now,
      );

      // Act
      final Map<String, dynamic> map = message.toMap();
      final ChatMessage fromMap = ChatMessage.fromMap(map);

      // Assert
      expect(fromMap.id, message.id);
      expect(fromMap.text, message.text);
      expect(fromMap.isUserMessage, message.isUserMessage);
      expect(fromMap.timestamp.toIso8601String(),
          message.timestamp.toIso8601String());
    });

    test('should clone a message correctly', () {
      // Arrange
      final DateTime now = DateTime.now();
      final List<AttachedFile> files = [
        AttachedFile(
          name: 'test.txt',
          path: '/path/to/test.txt',
          size: 4,
          type: 'txt',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        )
      ];

      final ChatMessage message = ChatMessage(
        id: '123',
        text: 'Check this file',
        isUserMessage: true,
        timestamp: now,
        attachedFiles: files,
      );

      // Act
      final ChatMessage clone = message.clone(deepCopyAttachments: true);

      // Assert
      expect(clone.id, message.id);
      expect(clone.text, message.text);
      expect(clone.isUserMessage, message.isUserMessage);
      expect(clone.timestamp, message.timestamp);
      expect(clone.attachedFiles, isNotNull);
      expect(clone.attachedFiles!.length, 1);
      expect(clone.attachedFiles![0].name, 'test.txt');

      // Verify it's a deep copy by checking that modifying the clone doesn't affect the original
      clone.attachedFiles![0].clearBytes();
      expect(message.attachedFiles![0].bytes, isNotNull);
    });
  });

  group('AttachedFile', () {
    test('should create an AttachedFile instance properly', () {
      // Arrange & Act
      final AttachedFile file = AttachedFile(
        name: 'test.txt',
        path: '/path/to/test.txt',
        size: 4,
        type: 'txt',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      // Assert
      expect(file.name, 'test.txt');
      expect(file.path, '/path/to/test.txt');
      expect(file.size, 4);
      expect(file.type, 'txt');
      expect(file.bytes, isNotNull);
      expect(file.isText, true);
      expect(file.isImage, false);
    });

    test('should convert to and from Map correctly', () {
      // Arrange
      final AttachedFile file = AttachedFile(
        id: '123',
        messageId: '456',
        name: 'test.txt',
        path: '/path/to/test.txt',
        size: 4,
        type: 'txt',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      // Act
      final Map<String, dynamic> map = file.toMap();
      final AttachedFile fromMap = AttachedFile.fromMap(map);

      // Assert
      expect(fromMap.id, file.id);
      expect(fromMap.messageId, file.messageId);
      expect(fromMap.name, file.name);
      expect(fromMap.path, file.path);
      expect(fromMap.size, file.size);
      expect(fromMap.type, file.type);
    });

    test('should identify file types correctly', () {
      // Text file
      final AttachedFile textFile = AttachedFile(
        name: 'test.txt',
        path: '/path/to/test.txt',
        size: 4,
        type: 'txt',
      );
      expect(textFile.isText, true);
      expect(textFile.isImage, false);

      // Image file
      final AttachedFile imageFile = AttachedFile(
        name: 'image.jpg',
        path: '/path/to/image.jpg',
        size: 1024,
        type: 'jpg',
      );
      expect(imageFile.isText, false);
      expect(imageFile.isImage, true);
    });

    test('clearBytes should remove byte data', () {
      // Arrange
      final AttachedFile file = AttachedFile(
        name: 'test.txt',
        path: '/path/to/test.txt',
        size: 4,
        type: 'txt',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      // Act
      file.clearBytes();

      // Assert
      expect(file.bytes, isNull);
      expect(file.hasLoadedBytes, false);
    });
  });
}
