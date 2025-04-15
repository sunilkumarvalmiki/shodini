import 'package:equatable/equatable.dart';
import 'package:llm_app/data/models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatHistoryEvent extends ChatEvent {
  const LoadChatHistoryEvent();
}

class SendMessageEvent extends ChatEvent {
  final String text;

  const SendMessageEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class AttachFileEvent extends ChatEvent {
  const AttachFileEvent();
}

class RemoveAttachmentEvent extends ChatEvent {
  final int index;

  const RemoveAttachmentEvent(this.index);

  @override
  List<Object?> get props => [index];
}

class ClearChatHistoryEvent extends ChatEvent {
  const ClearChatHistoryEvent();
}

// Event to track which messages are currently visible in the UI
// This helps optimize memory by clearing attachment bytes from non-visible messages
class UpdateVisibleMessagesEvent extends ChatEvent {
  final int startIndex;
  final int endIndex;

  const UpdateVisibleMessagesEvent({
    required this.startIndex,
    required this.endIndex,
  });

  @override
  List<Object?> get props => [startIndex, endIndex];
}
