import 'package:equatable/equatable.dart';
import 'package:llm_app/data/models/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final List<AttachedFile> currentAttachments;
  final bool isLoading;
  final bool isAttaching;

  const ChatLoaded({
    required this.messages,
    required this.currentAttachments,
    this.isLoading = false,
    this.isAttaching = false,
  });

  @override
  List<Object?> get props => [
        messages,
        currentAttachments,
        isLoading,
        isAttaching,
      ];

  // Helper method to create a copy with modified properties
  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    List<AttachedFile>? currentAttachments,
    bool? isLoading,
    bool? isAttaching,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentAttachments: currentAttachments ?? this.currentAttachments,
      isLoading: isLoading ?? this.isLoading,
      isAttaching: isAttaching ?? this.isAttaching,
    );
  }
}

class ChatError extends ChatState {
  final String message;
  final ChatState? prevState;

  const ChatError({
    required this.message,
    this.prevState,
  });

  @override
  List<Object?> get props => [message, prevState];
}

class ChatFileError extends ChatState {
  final String message;
  final ChatState prevState;

  const ChatFileError({
    required this.message,
    required this.prevState,
  });

  @override
  List<Object?> get props => [message, prevState];
}
