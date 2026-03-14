import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/citation.dart';
import '../services/job_service.dart';
import 'app_providers.dart';

class ChatMessage {
  const ChatMessage({
    required this.content,
    required this.isUser,
    this.citations,
  });

  final String content;
  final bool isUser;
  final List<Citation>? citations;
}

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._service, this.jobId) : super([]);

  final JobService _service;
  final int jobId;

  Future<void> sendMessage(String message) async {
    state = [...state, ChatMessage(content: message, isUser: true)];

    try {
      final result = await _service.chatWithJobDetailed(jobId, message);
      state = [
        ...state,
        ChatMessage(
          content: result.answer,
          isUser: false,
          citations: result.citations,
        ),
      ];
    } catch (_) {
      state = [
        ...state,
        const ChatMessage(
          content: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
        ),
      ];
    }
  }
}

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, List<ChatMessage>, int>(
        (ref, jobId) {
  return ChatController(ref.watch(jobServiceProvider), jobId);
});
