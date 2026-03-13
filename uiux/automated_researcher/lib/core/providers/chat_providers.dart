import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/job_service.dart';
import 'app_providers.dart';

class ChatMessage {
  ChatMessage({required this.content, required this.isUser});

  final String content;
  final bool isUser;
}

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController(this._service, this.jobId) : super([]);

  final JobService _service;
  final int jobId;

  Future<void> sendMessage(String message) async {
    state = [...state, ChatMessage(content: message, isUser: true)];
    final reply = await _service.chatWithJob(jobId, message);
    state = [...state, ChatMessage(content: reply, isUser: false)];
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController, List<ChatMessage>, int>((ref, jobId) {
  return ChatController(ref.watch(jobServiceProvider), jobId);
});