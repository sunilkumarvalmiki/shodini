import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:llm_app/data/models/chat_message.dart';
import 'package:llm_app/data/repositories/chat_repository.dart';
import 'package:llm_app/presentation/blocs/chat/chat_event.dart';
import 'package:llm_app/presentation/blocs/chat/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB limit
  
  // Cache for recently processed files to avoid reprocessing
  final Map<String, AttachedFile> _fileCache = {};
  // Maximum number of files to keep in cache
  static const int _maxCacheSize = 20;
  
  // Keep track of visible message range to optimize memory
  int _visibleStartIndex = 0;
  int _visibleEndIndex = 0;
  static const int _visibleBufferSize = 5; // Keep 5 extra messages in memory

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatInitial()) {
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<AttachFileEvent>(_onAttachFile);
    on<RemoveAttachmentEvent>(_onRemoveAttachment);
    on<ClearChatHistoryEvent>(_onClearChatHistory);
    on<UpdateVisibleMessagesEvent>(_onUpdateVisibleMessages);
  }

  // Clear memory when bloc is closed
  @override
  Future<void> close() {
    _clearFileCache();
    return super.close();
  }

  // Clean up memory by clearing the file cache
  void _clearFileCache() {
    _fileCache.clear();
  }

  // Manage cache size by removing oldest entries when needed
  void _manageFileCache() {
    if (_fileCache.length > _maxCacheSize) {
      final keysToRemove = _fileCache.keys.take(_fileCache.length - _maxCacheSize);
      for (final key in keysToRemove) {
        _fileCache.remove(key);
      }
    }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    try {
      // Use batched loading for better performance with large histories
      final messages = await _loadMessagesInBatches();
      
      // When loading is complete, set initial visible range
      _visibleStartIndex = 0;
      _visibleEndIndex = messages.length > 10 ? 10 : messages.length;
      
      emit(ChatLoaded(messages: messages, currentAttachments: const []));
    } catch (e) {
      emit(ChatError(message: 'Failed to load chat history: $e'));
      emit(const ChatLoaded(messages: [], currentAttachments: []));
    }
  }
  
  // Load messages in batches to avoid UI freezing with large histories
  Future<List<ChatMessage>> _loadMessagesInBatches() async {
    // First, get count of messages to determine if batching is needed
    final messageCount = await _chatRepository.getMessageCount();
    
    // If we have a small number of messages, load them all at once
    if (messageCount < 50) {
      final messages = await _chatRepository.getMessages();
      // Use compute for parsing large data sets
      return await compute(_reverseMessageList, messages);
    }
    
    // For large message histories, load in batches
    // First load the most recent messages quickly
    final recentMessages = await _chatRepository.getMessageBatch(0, 20);
    final reversedRecent = await compute(_reverseMessageList, recentMessages);
    
    // Then load older messages in the background
    _loadOlderMessagesInBackground(messageCount);
    
    return reversedRecent;
  }
  
  // Load older messages in background to keep UI responsive
  Future<void> _loadOlderMessagesInBackground(int totalCount) async {
    // Skip the most recent 20 messages we've already loaded
    const alreadyLoaded = 20;
    const batchSize = 30;
    
    // Calculate how many batches we need
    final remainingMessages = totalCount - alreadyLoaded;
    final batchCount = (remainingMessages / batchSize).ceil();
    
    for (int i = 0; i < batchCount; i++) {
      // Check if we're still in the same state (user hasn't navigated away)
      if (state is! ChatLoaded) return;
      
      final offset = alreadyLoaded + (i * batchSize);
      final batch = await _chatRepository.getMessageBatch(offset, batchSize);
      
      if (batch.isNotEmpty && state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final reversedBatch = await compute(_reverseMessageList, batch);
        
        // Merge with existing messages
        final updatedMessages = List<ChatMessage>.from(currentState.messages)
          ..addAll(reversedBatch);
        
        emit(currentState.copyWith(messages: updatedMessages));
      }
      
      // Small delay to not overload the UI thread
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Helper function to run on a separate isolate
  static List<ChatMessage> _reverseMessageList(List<ChatMessage> messages) {
    return messages.reversed.toList();
  }
  
  // Update which messages are currently visible in the UI
  Future<void> _onUpdateVisibleMessages(
    UpdateVisibleMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final messages = currentState.messages;
      
      // Update visible range with buffer
      _visibleStartIndex = event.startIndex > _visibleBufferSize ? 
          event.startIndex - _visibleBufferSize : 0;
      
      _visibleEndIndex = event.endIndex + _visibleBufferSize < messages.length ?
          event.endIndex + _visibleBufferSize : messages.length - 1;
      
      // Clear attachment bytes for messages well outside visible range
      // to free up memory
      await compute(_optimizeMessageMemory, _MessageOptimizationParams(
        messages: messages,
        visibleStartIndex: _visibleStartIndex,
        visibleEndIndex: _visibleEndIndex,
        totalCount: messages.length
      ));
    }
  }
  
  // Data class for message optimization parameters
  static class _MessageOptimizationParams {
    final List<ChatMessage> messages;
    final int visibleStartIndex;
    final int visibleEndIndex;
    final int totalCount;
    
    _MessageOptimizationParams({
      required this.messages,
      required this.visibleStartIndex,
      required this.visibleEndIndex,
      required this.totalCount,
    });
  }
  
  // Optimize message memory in background
  static void _optimizeMessageMemory(_MessageOptimizationParams params) {
    final messages = params.messages;
    final visibleStart = params.visibleStartIndex;
    final visibleEnd = params.visibleEndIndex;
    
    // Clear memory for messages well outside visible range
    for (int i = 0; i < messages.length; i++) {
      if (i < visibleStart - 10 || i > visibleEnd + 10) {
        messages[i].clearAttachmentBytes();
      }
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final text = event.text;
      final currentAttachments = currentState.currentAttachments;
      
      // Skip empty messages with no attachments
      if (text.trim().isEmpty && (currentAttachments.isEmpty)) {
        return;
      }

      // Create user message
      final userMessage = ChatMessage(
        text: text,
        isUserMessage: true,
        timestamp: DateTime.now(),
        attachedFiles: currentAttachments.isEmpty ? null : List.from(currentAttachments),
      );

      // Update state with new message and loading indicator
      final updatedMessages = List<ChatMessage>.from(currentState.messages)
        ..add(userMessage);
      emit(
        ChatLoaded(
          messages: updatedMessages,
          currentAttachments: const [],
          isLoading: true,
        ),
      );

      // Save message asynchronously
      unawaited(_chatRepository.saveMessage(userMessage));

      // Generate bot response asynchronously
      // Use compute for generating response if it's complex
      final botResponseText = await compute(
        _generateBotResponse,
        _BotResponseParams(
          userMessage: text,
          attachedFiles: userMessage.attachedFiles,
        ),
      );

      // Create bot message
      final botMessage = ChatMessage(
        text: botResponseText,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );

      // Update state with bot message
      final messagesWithBotResponse = List<ChatMessage>.from(updatedMessages)
        ..add(botMessage);
      emit(
        ChatLoaded(
          messages: messagesWithBotResponse,
          currentAttachments: const [],
          isLoading: false,
        ),
      );

      // Save bot message asynchronously
      unawaited(_chatRepository.saveMessage(botMessage));
    }
  }

  // Helper method to properly unawaited a Future
  void unawaited(Future future) {
    future.catchError((e) {
      print('Error in background operation: $e');
    });
  }

  // Helper class for passing parameters to isolate
  static class _BotResponseParams {
    final String userMessage;
    final List<AttachedFile>? attachedFiles;

    _BotResponseParams({required this.userMessage, this.attachedFiles});
  }

  // Generate bot response in separate isolate
  static String _generateBotResponse(_BotResponseParams params) {
    final userMessage = params.userMessage;
    final files = params.attachedFiles;

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
      return '''Currently you're using a simulated version of the LLM model.

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

In a production app, this would be replaced with an actual LLM response.

Some things you might want to try:
1. Asking a specific question
2. Uploading a file for analysis
3. Trying a different model from the dropdown above''';
    }
  }

  // Rest of the class remains the same...
} 