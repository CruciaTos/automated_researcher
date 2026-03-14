import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/desktop_theme.dart';

// ─── Message model ────────────────────────────────────────────────────────────

class _Message {
  const _Message({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });

  final String text;
  final bool   isUser;
  final bool   isLoading;
}

// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dt.bgPage,
      appBar: AppBar(
        backgroundColor: Dt.bgSidebar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Dt.textSecondary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/desktop/reports');
            }
          },
        ),
        title: Text('Chat — Job #${widget.jobId}', style: Dt.cardTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Dt.border),
        ),
      ),
      body: Column(
        children: [
          // ── Messages area ────────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? const _EmptyChat()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(24),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) =>
                        _Bubble(msg: _messages[i]),
                  ),
          ),

          // ── Input bar ────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Dt.border)),
              color: Dt.bgCard,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask a question about this research…',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Dt.textMuted),
                      filled: true,
                      fillColor: Dt.bgInput,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(Dt.inputRadius),
                        borderSide: const BorderSide(color: Dt.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(Dt.inputRadius),
                        borderSide: const BorderSide(color: Dt.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(Dt.inputRadius),
                        borderSide: const BorderSide(
                            color: Dt.borderFocus, width: 1.5),
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 13, color: Dt.textPrimary),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Dt.primary,
                      disabledBackgroundColor:
                          Dt.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dt.inputRadius),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final question = _inputCtrl.text.trim();
    if (question.isEmpty || _sending) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_Message(text: question, isUser: true));
      _messages.add(
          const _Message(text: '', isUser: false, isLoading: true));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final client = ref.read(apiClientProvider);
      final json   = await client.post(
        '/jobs/${widget.jobId}/chat',
        body: {'question': question},
      );
      final answer =
          (json as Map<String, dynamic>)['answer'] as String? ??
              'No answer available.';

      setState(() {
        _messages.removeLast(); // remove loading bubble
        _messages.add(_Message(text: answer, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(
            _Message(text: 'Error: ${e.toString()}', isUser: false));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Dt.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.chat_outlined,
                  size: 26, color: Dt.primary),
            ),
            const SizedBox(height: 14),
            const Text('Ask anything about this research',
                style: Dt.cardTitle),
            const SizedBox(height: 6),
            const Text(
              'The AI answers using the indexed sources for this job.',
              style: Dt.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});

  final _Message msg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Dt.primaryLight,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  size: 14, color: Dt.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:  msg.isUser ? Dt.primary : Dt.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: msg.isUser
                    ? null
                    : Border.all(color: Dt.border),
              ),
              child: msg.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Dt.textMuted),
                    )
                  : Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: msg.isUser
                            ? Colors.white
                            : Dt.textPrimary,
                        height: 1.55,
                      ),
                    ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Dt.primaryLight,
              child: Icon(Icons.person_outline_rounded,
                  size: 15, color: Dt.primary),
            ),
          ],
        ],
      ),
    );
  }
}
