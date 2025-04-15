import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Database name
  static const String _databaseName = "llm_app.db";

  // Database version
  static const int _databaseVersion = 1;

  // Table names
  static const String tableMessages = 'messages';
  static const String tableAttachedFiles = 'attached_files';

  // Common columns
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';

  // Message table columns
  static const String columnText = 'text';
  static const String columnIsUserMessage = 'is_user_message';
  static const String columnTimestamp = 'timestamp';

  // Attached files table columns
  static const String columnMessageId = 'message_id';
  static const String columnName = 'name';
  static const String columnPath = 'path';
  static const String columnSize = 'size';
  static const String columnType = 'type';
  static const String columnBytes = 'bytes';

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Create and open the database
  Future<Database> _initDatabase() async {
    Directory? documentsDirectory;

    // For web platform, use in-memory database
    if (kIsWeb) {
      return openDatabase(
        inMemoryDatabasePath,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    }

    // For other platforms, use file system
    documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create messages table
    await db.execute('''
      CREATE TABLE $tableMessages (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnText TEXT NOT NULL,
        $columnIsUserMessage INTEGER NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');

    // Create attached files table
    await db.execute('''
      CREATE TABLE $tableAttachedFiles (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnMessageId INTEGER NOT NULL,
        $columnName TEXT NOT NULL,
        $columnPath TEXT,
        $columnSize INTEGER NOT NULL,
        $columnType TEXT NOT NULL,
        $columnBytes BLOB,
        $columnCreatedAt TEXT NOT NULL,
        FOREIGN KEY ($columnMessageId) REFERENCES $tableMessages ($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // Insert a message into the database
  Future<int> insertMessage(Map<String, dynamic> message) async {
    Database db = await database;
    message[columnCreatedAt] = DateTime.now().toIso8601String();
    return await db.insert(tableMessages, message);
  }

  // Insert an attached file into the database
  Future<int> insertAttachedFile(Map<String, dynamic> file) async {
    Database db = await database;
    file[columnCreatedAt] = DateTime.now().toIso8601String();
    return await db.insert(tableAttachedFiles, file);
  }

  // Get all messages with their attached files
  Future<List<Map<String, dynamic>>> getMessages() async {
    Database db = await database;

    // Get all messages ordered by timestamp (newest first)
    List<Map<String, dynamic>> messages = await db.query(
      tableMessages,
      orderBy: '$columnTimestamp DESC',
    );

    // For each message, get its attached files
    for (var message in messages) {
      int messageId = message[columnId];
      List<Map<String, dynamic>> files = await db.query(
        tableAttachedFiles,
        where: '$columnMessageId = ?',
        whereArgs: [messageId],
      );

      // Add attached files to the message
      message['attachedFiles'] = files;
    }

    return messages;
  }

  // Delete a message and its attached files
  Future<int> deleteMessage(int id) async {
    Database db = await database;
    return await db.delete(
      tableMessages,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete all messages and attached files
  Future<int> deleteAllMessages() async {
    Database db = await database;
    return await db.delete(tableMessages);
  }
}
