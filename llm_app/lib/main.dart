import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:llm_app/core/router/app_router.dart';
import 'package:llm_app/core/router/route_guards.dart';
import 'package:llm_app/core/di/service_locator.dart';
import 'package:llm_app/core/theme/theme_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator
  await initServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: serviceLocator<ThemeService>(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            title: 'Open-Source LLM App',
            theme: themeService.getLightTheme(),
            darkTheme: themeService.getDarkTheme(),
            themeMode: themeService.flutterThemeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Simulate splash screen duration (3-5 seconds as per PRD)
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'Open-Source LLM App',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            // Version number
            Text(
              'v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize theme mode
    _isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ChatTab(),
      _buildDocsTab(),
      _buildMarketplaceTab(),
      _buildProfileTab(),
    ];

    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Open-Source LLM App'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
              tooltip: 'Toggle Theme',
            ),
          ],
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
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
      ),
    );
  }

  Widget _buildDocsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 60),
          SizedBox(height: 16),
          Text('Documents Tab', style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text('Coming in v2'),
        ],
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 60),
          const SizedBox(height: 16),
          const Text('Marketplace Tab', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          const Text('Discover and select models'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Browse Models'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 60),
          const SizedBox(height: 16),
          const Text('Profile Tab', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          const Text('Account, Appearance, Data Controls, Info'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _toggleTheme,
            child: Text(
                _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
          ),
        ],
      ),
    );
  }
}

// Chat Message model
class ChatMessage {
  final String? id;
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final List<AttachedFile>? attachedFiles;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.attachedFiles,
  });

  // Clear bytes from attached files to free memory when not in view
  void clearAttachmentBytes() {
    if (attachedFiles != null) {
      for (final file in attachedFiles!) {
        file.clearBytes();
      }
    }
  }
}

class AttachedFile {
  final String? id;
  final String name;
  final String path;
  final int size;
  final String type;
  Uint8List? bytes;

  // Memory management flags
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get hasBytes => bytes != null;
  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(type.toLowerCase());

  AttachedFile({
    this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    this.bytes,
  });

  // Clear bytes to free memory
  void clearBytes() {
    bytes = null;
  }

  // Load bytes efficiently with memory optimization
  Future<void> loadBytes() async {
    if (bytes != null || _isLoading || path.isEmpty) return;

    _isLoading = true;
    try {
      if (!kIsWeb && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          // Load bytes in chunks for very large files
          if (size > 5 * 1024 * 1024) {
            // 5MB threshold
            // Use compute for background processing of heavy loads
            bytes = await compute(_readFileBytesIsolate, path);
          } else {
            bytes = await file.readAsBytes();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading file bytes: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Static method for isolate to read file bytes
  static Future<Uint8List> _readFileBytesIsolate(String path) async {
    final file = File(path);
    return await file.readAsBytes();
  }
}

// Chat Tab
class ChatTab extends StatefulWidget {
  const ChatTab({Key? key}) : super(key: key);

  @override
  _ChatTabState createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _selectedModel = 'GPT-3.5 Turbo';
  List<AttachedFile> _currentAttachments = [];
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB as per PRD
  int _previousFirstVisibleIndex = 0;
  int _previousLastVisibleIndex = 0;
  // Throttle scroll events to avoid excessive rebuilds
  DateTime _lastScrollUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Add scroll listener to manage memory for image attachments
    _scrollController.addListener(_manageAttachmentMemory);
    _scrollController.addListener(_handleScrollForVisibleMessages);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_manageAttachmentMemory);
    _scrollController.removeListener(_handleScrollForVisibleMessages);
    _scrollController.dispose();
    super.dispose();
  }

  // Track which messages are visible in the viewport
  void _handleScrollForVisibleMessages() {
    if (!_scrollController.hasClients || _messages.isEmpty) return;

    // Throttle updates to once every 500ms for better performance
    final now = DateTime.now();
    if (now.difference(_lastScrollUpdate).inMilliseconds < 500) return;
    _lastScrollUpdate = now;

    final visibleItemsInfo = _getVisibleItemsInfo();
    if (visibleItemsInfo == null) return;

    final firstVisibleIndex = visibleItemsInfo.firstVisibleIndex;
    final lastVisibleIndex = visibleItemsInfo.lastVisibleIndex;

    // Only update if the visible range has changed significantly
    if ((firstVisibleIndex - _previousFirstVisibleIndex).abs() > 3 ||
        (lastVisibleIndex - _previousLastVisibleIndex).abs() > 3) {
      _previousFirstVisibleIndex = firstVisibleIndex;
      _previousLastVisibleIndex = lastVisibleIndex;

      // In a real app with ChatBloc, would dispatch:
      // context.read<ChatBloc>().add(
      //   UpdateVisibleMessagesEvent(
      //     startIndex: firstVisibleIndex,
      //     endIndex: lastVisibleIndex,
      //   ),
      // );

      // For now, directly call the memory management
      _clearMemoryForNonVisibleMessages(firstVisibleIndex, lastVisibleIndex);
    }
  }

  // Clear image data for messages that are not visible
  void _clearMemoryForNonVisibleMessages(int firstVisible, int lastVisible) {
    // Keep a buffer of 5 messages in each direction
    const buffer = 5;
    final minKeep = firstVisible - buffer;
    final maxKeep = lastVisible + buffer;

    for (int i = 0; i < _messages.length; i++) {
      if (i < minKeep || i > maxKeep) {
        _messages[i].clearAttachmentBytes();
      }
    }
  }

  // Clear bytes from messages that are no longer visible to free memory
  void _manageAttachmentMemory() {
    // Implementation moved to _handleScrollForVisibleMessages
  }

  // Helper to get visible items range information
  _VisibleItemsInfo? _getVisibleItemsInfo() {
    if (!_scrollController.hasClients) return null;

    final ScrollPosition position = _scrollController.position;
    final double viewportHeight = position.viewportDimension;
    final double scrollOffset = position.pixels;

    // Estimate average item height (can be improved)
    const double estimatedItemHeight = 150.0;

    final int firstVisibleIndex = (scrollOffset / estimatedItemHeight).floor();
    final int lastVisibleIndex =
        ((scrollOffset + viewportHeight) / estimatedItemHeight).ceil();

    return _VisibleItemsInfo(
      firstVisibleIndex: firstVisibleIndex.clamp(0, _messages.length - 1),
      lastVisibleIndex: lastVisibleIndex.clamp(0, _messages.length - 1),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _currentAttachments.isEmpty) {
      return;
    }

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: _messageController.text,
      isUserMessage: true,
      timestamp: DateTime.now(),
      attachedFiles:
          _currentAttachments.isEmpty ? null : List.from(_currentAttachments),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
      _currentAttachments = [];
    });

    _scrollToBottom();

    // Simulate LLM response after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final botText =
            _generateBotResponse(userMessage.text, userMessage.attachedFiles);
        final botMessage = ChatMessage(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          text: botText,
          isUserMessage: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });

        _scrollToBottom();
      }
    });
  }

  String _generateBotResponse(String userMessage, List<AttachedFile>? files) {
    if (files != null && files.isNotEmpty) {
      final fileNames = files.map((f) => f.name).join(', ');
      return '''I've received your message and the following files: **$fileNames**. 

In a production app, I would process these files and analyze their content. This is a placeholder response that would be replaced with an actual LLM response.

Here's what I can do with these files:
* Extract text content
* Analyze images
* Process structured data
* Provide summaries and insights

Is there something specific you'd like to know about these files?''';
    }

    if (userMessage.toLowerCase().contains('hello') ||
        userMessage.toLowerCase().contains('hi')) {
      return '''Hello! How can I assist you today?

I can help with:
* Answering questions
* Providing information
* Having conversations
* Processing files you share''';
    } else if (userMessage.toLowerCase().contains('help')) {
      return '''I'm here to help! You can ask me questions, request information, or have a conversation.

**Commands you can try:**
* Ask general knowledge questions
* Inquire about the app features
* Upload files for analysis
* Ask about available models

In the production app, I would be connected to an actual LLM for more advanced responses.''';
    } else if (userMessage.toLowerCase().contains('model')) {
      return '''Currently you're using a simulated version of **$_selectedModel**.

In the production app, this would be connected to the actual model. Different models have different capabilities and performance characteristics.

| Model | Specialty | Token Limit |
|-------|-----------|-------------|
| GPT-3.5 Turbo | General purpose | 4k |
| GPT-4 | Advanced reasoning | 8k |
| Claude 3 Opus | Detailed analysis | 100k |
| Claude 3 Sonnet | Creative writing | 100k |
| Llama 3 | Open source | 8k |''';
    } else {
      return '''This is a placeholder response for "$userMessage".

In a production app, this would be replaced with an actual LLM response from **$_selectedModel**.

Some things you might want to try:
1. Asking a specific question
2. Uploading a file for analysis
3. Trying a different model from the dropdown above''';
    }
  }

  Future<void> _attachFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'docx',
          'txt',
          'jpg',
          'png',
          'jpeg',
          'csv',
          'xlsx'
        ],
        allowMultiple: true,
        withData: true, // Get the file data as bytes
      );

      if (result != null && result.files.isNotEmpty) {
        List<AttachedFile> newAttachments = [];
        List<String> oversizedFiles = [];

        for (final file in result.files) {
          // Check file size
          if (file.size > _maxFileSizeBytes) {
            oversizedFiles.add(file.name);
            continue;
          }

          // Get file extension
          String fileType = file.extension?.toLowerCase() ?? '';

          // For web platform, path is not available, so we'll use a placeholder
          // In a real app, you would handle bytes directly for web
          final filePath = kIsWeb ? '' : (file.path ?? '');

          newAttachments.add(AttachedFile(
            id: file.name,
            name: file.name,
            path: filePath,
            size: file.size,
            type: fileType,
            bytes: file.bytes, // Store bytes for web platform
          ));
        }

        if (oversizedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Some files exceed the 10MB limit: ${oversizedFiles.join(", ")}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        if (newAttachments.isNotEmpty) {
          setState(() {
            _currentAttachments = [..._currentAttachments, ...newAttachments];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _currentAttachments.removeAt(index);
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Helper method to read text files
  Future<String> _readTextFileContent(AttachedFile file) async {
    try {
      if (kIsWeb) {
        // For web platform, use bytes
        if (file.bytes != null) {
          try {
            return utf8.decode(file.bytes!);
          } catch (e) {
            // If UTF-8 decoding fails, try Latin-1
            return latin1.decode(file.bytes!);
          }
        }
        return 'No content available';
      } else {
        // For non-web platforms, use path
        if (file.path.isNotEmpty) {
          final fileObj = File(file.path);
          List<int> bytes = await fileObj.readAsBytes();
          try {
            return utf8.decode(bytes);
          } catch (e) {
            // If UTF-8 decoding fails, try Latin-1
            return latin1.decode(bytes);
          }
        }
        return 'No content available';
      }
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  // Helper method to build image preview based on platform
  Widget _buildImagePreview(
      AttachedFile file, bool isUserMessage, BuildContext context) {
    if (kIsWeb) {
      // For web platform, use bytes
      if (file.bytes != null) {
        return Image.memory(
          Uint8List.fromList(file.bytes!),
          height: 150,
          width: 200,
          fit: BoxFit.cover,
          cacheHeight: 600, // Limit memory usage by constraining cache size
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null) {
              return const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPreview();
          },
        );
      }
      return _buildNoPreviewAvailable();
    } else {
      // For non-web platforms, use path
      if (file.path.isNotEmpty) {
        // Use FutureBuilder to handle image loading errors gracefully
        return FutureBuilder<File>(
          future: DefaultCacheManager().getSingleFile(file.path),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorPreview();
            } else {
              return Image.file(
                snapshot.data!,
                height: 150,
                width: 200,
                fit: BoxFit.cover,
                cacheHeight: 600, // Limit memory usage
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame == null) {
                    return const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return child;
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPreview();
                },
              );
            }
          },
        );
      }
      return _buildNoPreviewAvailable();
    }
  }

  Widget _buildErrorPreview() {
    return Container(
      height: 100,
      width: 150,
      color: Colors.grey.withOpacity(0.3),
      child: const Center(
        child: Text('Image not available'),
      ),
    );
  }

  Widget _buildNoPreviewAvailable() {
    return Container(
      height: 100,
      width: 150,
      color: Colors.grey.withOpacity(0.3),
      child: const Center(
        child: Text('No preview available'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildModelSelector(),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? const _EmptyChat() : _buildChatList(),
          ),
          if (_isLoading) _buildLoadingIndicator(),
          if (_currentAttachments.isNotEmpty) _buildAttachmentsList(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Separate widget methods for better performance

  Widget _buildModelSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: _selectedModel,
            isExpanded: true,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedModel = newValue;
                });
              }
            },
            items: const [
              DropdownMenuItem(
                  value: 'GPT-3.5 Turbo', child: Text('GPT-3.5 Turbo')),
              DropdownMenuItem(value: 'GPT-4', child: Text('GPT-4')),
              DropdownMenuItem(
                  value: 'Claude 3 Opus', child: Text('Claude 3 Opus')),
              DropdownMenuItem(
                  value: 'Claude 3 Sonnet', child: Text('Claude 3 Sonnet')),
              DropdownMenuItem(value: 'Llama 3', child: Text('Llama 3')),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Placeholder for model settings
          },
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      padding: const EdgeInsets.all(16.0),
      cacheExtent: 1000, // Cache more items for smoother scrolling
      addAutomaticKeepAlives: false, // Don't keep invisible items alive
      findChildIndexCallback: (key) {
        // Optimize rebuilds by properly identifying items by key
        if (key is ValueKey<String>) {
          final messageId = key.value;
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].id == messageId) {
              return i;
            }
          }
        }
        return null;
      },
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageItem(
          key: ValueKey<String>(message.id ?? '$index'),
          message: message,
          formatFileSize: _formatFileSize,
          buildImagePreview: _buildImagePreview,
          readTextFileContent: _readTextFileContent,
          buildErrorPreview: _buildErrorPreview,
          buildNoPreviewAvailable: _buildNoPreviewAvailable,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Thinking...',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          for (int i = 0; i < _currentAttachments.length; i++)
            _AttachmentPreview(
              key: ValueKey('attachment_$i'),
              file: _currentAttachments[i],
              onRemove: () => _removeAttachment(i),
              formatFileSize: _formatFileSize,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _attachFile,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// Extracted widget for better performance - empty chat placeholder
class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Start a conversation by sending a message',
        style: TextStyle(
          color:
              Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
        ),
      ),
    );
  }
}

// Extracted widget for better performance - message item
class _MessageItem extends StatelessWidget {
  final ChatMessage message;
  final String Function(int) formatFileSize;
  final Widget Function(AttachedFile, bool, BuildContext) buildImagePreview;
  final Future<String> Function(AttachedFile) readTextFileContent;
  final Widget Function() buildErrorPreview;
  final Widget Function() buildNoPreviewAvailable;

  const _MessageItem({
    Key? key,
    required this.message,
    required this.formatFileSize,
    required this.buildImagePreview,
    required this.readTextFileContent,
    required this.buildErrorPreview,
    required this.buildNoPreviewAvailable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.isUserMessage
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachedFiles != null &&
                      message.attachedFiles!.isNotEmpty)
                    ...message.attachedFiles!
                        .map((file) => _buildAttachmentPreview(file, context))
                        .toList(),
                  _buildMessageContent(context),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUserMessage
                          ? Colors.white.withOpacity(0.8)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return message.isUserMessage
        ? Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
            ),
          )
        : MarkdownBody(
            data: message.text,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              h1: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              h2: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              h3: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              em: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
              strong: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              a: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              blockquote: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
              code: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                fontFamily: 'monospace',
              ),
              codeblockPadding: const EdgeInsets.all(8.0),
              tableHead: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              tableBody: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              tableBorder: TableBorder.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
              tableColumnWidth: const FixedColumnWidth(150),
              tableCellsPadding: const EdgeInsets.all(8.0),
              listBullet: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            selectable: true,
          );
  }

  Widget _buildAttachmentPreview(AttachedFile file, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  file.type == 'pdf'
                      ? Icons.picture_as_pdf
                      : file.type == 'docx'
                          ? Icons.description
                          : file.type == 'txt'
                              ? Icons.text_snippet
                              : file.type == 'jpg' ||
                                      file.type == 'png' ||
                                      file.type == 'jpeg'
                                  ? Icons.image
                                  : Icons.insert_drive_file,
                  size: 20,
                  color: message.isUserMessage
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: message.isUserMessage
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatFileSize(file.size),
                        style: TextStyle(
                          fontSize: 12,
                          color: message.isUserMessage
                              ? Colors.white.withOpacity(0.8)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Image preview for image files
          if (file.type == 'jpg' ||
              file.type == 'jpeg' ||
              file.type == 'png' ||
              file.type == 'gif' ||
              file.type == 'webp')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: OptimizedImagePreview(
                  file: file,
                  maxHeight: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Text file preview
          if (file.type == 'txt')
            FutureBuilder<String>(
              future: readTextFileContent(file),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Error loading text preview'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                      ),
                    ),
                    height: 100,
                    width: 200,
                    child: SingleChildScrollView(
                      child: Text(
                        snapshot.data!.length > 500
                            ? '${snapshot.data!.substring(0, 500)}...'
                            : snapshot.data!,
                        style: TextStyle(
                          fontSize: 12,
                          color: message.isUserMessage
                              ? Colors.white.withOpacity(0.9)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Extracted widget for better performance - attachment preview
class _AttachmentPreview extends StatelessWidget {
  final AttachedFile file;
  final VoidCallback onRemove;
  final String Function(int) formatFileSize;

  const _AttachmentPreview({
    Key? key,
    required this.file,
    required this.onRemove,
    required this.formatFileSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  file.type == 'pdf'
                      ? Icons.picture_as_pdf
                      : file.type == 'docx'
                          ? Icons.description
                          : file.type == 'txt'
                              ? Icons.text_snippet
                              : file.type == 'jpg' ||
                                      file.type == 'png' ||
                                      file.type == 'jpeg' ||
                                      file.type == 'gif' ||
                                      file.type == 'webp'
                                  ? Icons.image
                                  : file.type == 'csv' || file.type == 'xlsx'
                                      ? Icons.table_chart
                                      : Icons.insert_drive_file,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatFileSize(file.size),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // Show image preview for image types
            if (file.isImage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: OptimizedImagePreview(
                    file: file,
                    maxHeight: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper class for visible items information
class _VisibleItemsInfo {
  final int firstVisibleIndex;
  final int lastVisibleIndex;

  _VisibleItemsInfo({
    required this.firstVisibleIndex,
    required this.lastVisibleIndex,
  });
}

// OptimizedImagePreview widget for efficient image loading and display
class OptimizedImagePreview extends StatefulWidget {
  final AttachedFile file;
  final double maxHeight;
  final BoxFit fit;

  const OptimizedImagePreview({
    Key? key,
    required this.file,
    this.maxHeight = 200,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  State<OptimizedImagePreview> createState() => _OptimizedImagePreviewState();
}

class _OptimizedImagePreviewState extends State<OptimizedImagePreview> {
  bool _isLoading = false;
  final _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  Future<void> _loadImageData() async {
    if (widget.file.bytes != null || !widget.file.isImage) return;

    setState(() {
      _isLoading = true;
    });

    await widget.file.loadBytes();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.maxHeight,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      if (kIsWeb) {
        if (widget.file.bytes == null) {
          return const Center(
            heightFactor: 2.5,
            child: CircularProgressIndicator(),
          );
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: Image.memory(
            widget.file.bytes!,
            fit: widget.fit,
            filterQuality: FilterQuality.medium,
            cacheHeight: 600,
            frameBuilder: (_, child, frame, __) {
              if (frame == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return child;
            },
            errorBuilder: (_, __, ___) => _buildErrorWidget(),
          ),
        );
      } else {
        if (widget.file.path.startsWith('http')) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: CachedNetworkImage(
              imageUrl: widget.file.path,
              cacheManager: _cacheManager,
              fit: widget.fit,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (_, __, ___) => _buildErrorWidget(),
              fadeInDuration: const Duration(milliseconds: 150),
              memCacheWidth: 1200,
              memCacheHeight: 900,
              filterQuality: FilterQuality.medium,
            ),
          );
        } else if (widget.file.path.isNotEmpty) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: Image.file(
              File(widget.file.path),
              fit: widget.fit,
              cacheHeight: 800,
              cacheWidth: 1200,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              frameBuilder: (_, child, frame, __) {
                if (frame == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return child;
              },
              errorBuilder: (_, __, ___) => _buildErrorWidget(),
            ),
          );
        } else if (widget.file.bytes != null) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: Image.memory(
              widget.file.bytes!,
              fit: widget.fit,
              cacheHeight: 800,
              cacheWidth: 1200,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              frameBuilder: (_, child, frame, __) {
                if (frame == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return child;
              },
              errorBuilder: (_, __, ___) => _buildErrorWidget(),
            ),
          );
        } else {
          return _buildErrorWidget();
        }
      }
    } catch (e) {
      debugPrint('Error rendering image: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      height: widget.maxHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              'Unable to load image',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
