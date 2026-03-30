import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/citation.dart';
import '../models/api_error.dart';
import '../services/job_service.dart';
import 'app_providers.dart';

class ChatMessage {
  const ChatMessage({
    required this.content,
    required this.isUser,
    this.citations,
    this.isError = false,
  });

  final String content;
  final bool isUser;
  final List<Citation>? citations;
  final bool isError;
}

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._service, this.jobId) : super([]);

  final JobService _service;
  final int jobId;

  Future<void> retryLastUserMessage() async {
    final lastUser = state.lastWhere(
      (m) => m.isUser,
      orElse: () => const ChatMessage(content: '', isUser: true),
    );
    if (lastUser.content.isEmpty) return;
    await sendMessage(lastUser.content, addUserBubble: false);
  }

  Future<void> sendMessage(String message, {bool addUserBubble = true}) async {
    if (addUserBubble) {
      state = [...state, ChatMessage(content: message, isUser: true)];
    }
    try {
      final result = await _service.chatWithJobDetailed(jobId, message);
      state = [
        ...state,
        ChatMessage(
            content: result.answer,
            isUser: false,
            citations: result.citations),
      ];
    } catch (error) {
      const fallback = 'Sorry, something went wrong. Please try again.';
      final msg = error is ApiError && error.statusCode == 409
          ? 'Research is still processing, please wait'
          : fallback;
      state = [
        ...state,
        ChatMessage(content: msg, isUser: false, isError: true),
      ];
    }
  }
}

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, List<ChatMessage>, int>(
        (ref, jobId) {
  return ChatController(ref.watch(jobServiceProvider), jobId);
});
