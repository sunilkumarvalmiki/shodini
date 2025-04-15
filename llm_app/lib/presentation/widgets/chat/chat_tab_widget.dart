import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:llm_app/data/models/chat_message.dart';
import 'package:llm_app/data/repositories/chat_repository.dart';
import 'package:llm_app/presentation/widgets/chat/file_preview_widget.dart';

class ChatTabWidget extends StatefulWidget {
  const ChatTabWidget({Key? key}) : super(key: key);

  @override
  State<ChatTabWidget> createState() => _ChatTabWidgetState();
}

class _ChatTabWidgetState extends State<ChatTabWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatRepository _chatRepository = ChatRepository();
  bool _isLoading = false;
  String _selectedModel = 'GPT-3.5 Turbo';
  List<AttachedFile> _currentAttachments = [];
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB as per PRD
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _loadChatHistory() async {
    try {
      setState(() {
        _isLoadingHistory = true;
      });

      List<ChatMessage> savedMessages = await _chatRepository.getMessages();

      // Reverse to show oldest messages first
      savedMessages = savedMessages.reversed.toList();

      setState(() {
        _messages.clear();
        _messages.addAll(savedMessages);
        _isLoadingHistory = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _currentAttachments.isEmpty) {
      return;
    }

    final userMessage = ChatMessage(
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

    // Save user message to database
    _chatRepository.saveMessage(userMessage);

    // Simulate LLM response after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final botText =
            _generateBotResponse(userMessage.text, userMessage.attachedFiles);
        final botMessage = ChatMessage(
          text: botText,
          isUserMessage: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });

        // Save bot message to database
        _chatRepository.saveMessage(botMessage);

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
          final filePath = kIsWeb ? '' : (file.path ?? '');

          newAttachments.add(AttachedFile(
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Model selection header removed - now in App Bar
        Expanded(
          child: _isLoadingHistory
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation by sending a message',
                        style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      padding: const EdgeInsets.all(16.0),
                      // Add cacheExtent to improve performance when scrolling
                      cacheExtent: 1000,
                      // Add addAutomaticKeepAlives to prevent widget rebuilds when scrolling
                      addAutomaticKeepAlives: true,
                      // Add clipBehavior to reduce overdraw
                      clipBehavior: Clip.hardEdge,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Padding(
                          // Use proper keys for widget recycling
                          key: ValueKey('message_${message.id ?? index}'),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (message.attachedFiles != null &&
                                          message.attachedFiles!.isNotEmpty)
                                        ...message.attachedFiles!
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final int index = entry.key;
                                          final file = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .background
                                                        .withOpacity(0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        file.type == 'pdf'
                                                            ? Icons
                                                                .picture_as_pdf
                                                            : file.type ==
                                                                    'docx'
                                                                ? Icons
                                                                    .description
                                                                : file.type ==
                                                                        'txt'
                                                                    ? Icons
                                                                        .text_snippet
                                                                    : file.type == 'jpg' ||
                                                                            file.type ==
                                                                                'png' ||
                                                                            file.type ==
                                                                                'jpeg'
                                                                        ? Icons
                                                                            .image
                                                                        : file.type == 'csv' ||
                                                                                file.type == 'xlsx'
                                                                            ? Icons.table_chart
                                                                            : Icons.insert_drive_file,
                                                        size: 20,
                                                        color: message
                                                                .isUserMessage
                                                            ? Colors.white
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              file.name,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: message
                                                                        .isUserMessage
                                                                    ? Colors
                                                                        .white
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            Text(
                                                              _formatFileSize(
                                                                  file.size),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: message
                                                                        .isUserMessage
                                                                    ? Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.8)
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withOpacity(
                                                                            0.8),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Image preview for image files - use visibility aware component for lazy loading
                                                if (file.type == 'jpg' ||
                                                    file.type == 'jpeg' ||
                                                    file.type == 'png')
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8.0),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                      child:
                                                          VisibilityAwareFilePreview(
                                                        file: file,
                                                        visibilityKey:
                                                            '${message.id}_$index',
                                                        showControls: false,
                                                      ),
                                                    ),
                                                  ),
                                                // Text file preview
                                                if (file.type == 'txt')
                                                  FutureBuilder<String>(
                                                    future:
                                                        _readTextFileContent(
                                                            file),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: 8.0),
                                                          child: SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                          ),
                                                        );
                                                      }

                                                      if (snapshot.hasError ||
                                                          !snapshot.hasData) {
                                                        return const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  top: 8.0),
                                                          child: Text(
                                                              'Error loading text preview'),
                                                        );
                                                      }

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8.0),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .surface
                                                                .withOpacity(
                                                                    0.5),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            border: Border.all(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .outline
                                                                  .withOpacity(
                                                                      0.3),
                                                            ),
                                                          ),
                                                          height: 100,
                                                          width: 200,
                                                          // Use more efficient text rendering
                                                          child:
                                                              SingleChildScrollView(
                                                            child: Text(
                                                              snapshot.data!
                                                                          .length >
                                                                      500
                                                                  ? '${snapshot.data!.substring(0, 500)}...'
                                                                  : snapshot
                                                                      .data!,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: message
                                                                        .isUserMessage
                                                                    ? Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.9)
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface,
                                                              ),
                                                              maxLines: 10,
                                                              overflow:
                                                                  TextOverflow
                                                                      .fade,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      message.isUserMessage
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
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                h1: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                h2: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                h3: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                em: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.9),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                strong: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                a: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                                blockquote: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.8),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                code: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .surfaceVariant,
                                                  fontFamily: 'monospace',
                                                ),
                                                codeblockPadding:
                                                    const EdgeInsets.all(8.0),
                                                tableHead: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                tableBody: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                tableBorder: TableBorder.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline
                                                      .withOpacity(0.5),
                                                  width: 1,
                                                ),
                                                tableColumnWidth:
                                                    const FixedColumnWidth(150),
                                                tableCellsPadding:
                                                    const EdgeInsets.all(8.0),
                                                listBullet: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              selectable: true,
                                            ),
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
                      },
                    ),
        ),
        if (_isLoading)
          Padding(
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
          ),
        if (_currentAttachments.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                for (int i = 0; i < _currentAttachments.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _currentAttachments[i].type == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : _currentAttachments[i].type == 'docx'
                                        ? Icons.description
                                        : _currentAttachments[i].type == 'txt'
                                            ? Icons.text_snippet
                                            : _currentAttachments[i].type ==
                                                        'jpg' ||
                                                    _currentAttachments[i]
                                                            .type ==
                                                        'png' ||
                                                    _currentAttachments[i]
                                                            .type ==
                                                        'jpeg'
                                                ? Icons.image
                                                : _currentAttachments[i].type ==
                                                            'csv' ||
                                                        _currentAttachments[i]
                                                                .type ==
                                                            'xlsx'
                                                    ? Icons.table_chart
                                                    : Icons.insert_drive_file,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentAttachments[i].name,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatFileSize(_currentAttachments[i].size),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                constraints: const BoxConstraints(
                                  minHeight: 32,
                                  minWidth: 32,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => _removeAttachment(i),
                                tooltip: 'Remove file',
                              ),
                            ],
                          ),
                          // Add lazy-loaded image preview for image files
                          if (_currentAttachments[i].type == 'jpg' ||
                              _currentAttachments[i].type == 'jpeg' ||
                              _currentAttachments[i].type == 'png')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: VisibilityAwareFilePreview(
                                file: _currentAttachments[i],
                                visibilityKey:
                                    'current_${_currentAttachments[i].name}_$i',
                                onDelete: () => _removeAttachment(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Container(
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
        ),
      ],
    );
  }
}
