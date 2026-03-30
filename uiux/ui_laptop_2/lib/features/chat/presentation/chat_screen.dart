import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/chat_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/citation_tile.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.jobId});
  final int jobId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  bool _hasText = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _inputCtrl.addListener(() {
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _inputCtrl.clear();
    _focusNode.unfocus();
    await ref
        .read(chatControllerProvider(widget.jobId).notifier)
        .sendMessage(text);
    setState(() => _isSending = false);
    _scrollToBottom();
    Future.delayed(
        const Duration(milliseconds: 100), () => _focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatControllerProvider(widget.jobId));
    if (messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => context.go('/jobs/${widget.jobId}/report'),
          color: AppColors.primaryText,
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Follow-up Chat',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                  fontFamily: 'GeneralSans')),
          Text('Powered by collected sources',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText,
                  fontFamily: 'GeneralSans')),
        ]),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(chatControllerProvider(widget.jobId).notifier)
                    .retryLastUserMessage();
              },
              color: AppColors.primaryText,
              backgroundColor: AppColors.surface,
              child: messages.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == messages.length && _isSending) {
                          return const _TypingIndicator();
                        }
                        return _Bubble(
                          key: ValueKey(i),
                          message: messages[i],
                          onRetry: messages[i].isError
                              ? () => ref
                                  .read(chatControllerProvider(widget.jobId)
                                      .notifier)
                                  .retryLastUserMessage()
                              : null,
                        );
                      },
                    ),
            ),
          ),
          _inputBar(context),
        ]),
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.background,
          border:
              Border(top: BorderSide(color: AppColors.border, width: 1))),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1)),
            child: TextField(
              controller: _inputCtrl,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryText,
                  height: 1.5,
                  fontFamily: 'GeneralSans'),
              decoration: const InputDecoration(
                hintText: 'Ask a follow-up question…',
                hintStyle: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                    fontFamily: 'GeneralSans'),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (_hasText && !_isSending)
                ? AppColors.primaryText
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (_hasText && !_isSending)
                    ? AppColors.primaryText
                    : AppColors.border,
                width: 1),
          ),
          child: IconButton(
            onPressed: (_hasText && !_isSending) ? _send : null,
            icon: Icon(Icons.arrow_upward_rounded,
                size: 18,
                color: (_hasText && !_isSending)
                    ? AppColors.background
                    : AppColors.mutedText),
            padding: EdgeInsets.zero,
          ),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1)),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    size: 24, color: AppColors.mutedText),
              ),
              const SizedBox(height: 20),
              const Text('Ask anything about\nyour research',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                      letterSpacing: -0.3,
                      height: 1.3,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 8),
              const Text('Answers are grounded in collected sources only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                      height: 1.4,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  'Summarize key findings',
                  'What are the limitations?',
                  'Key controversies',
                ]
                    .map((q) => _SuggestionChip(
                        label: q,
                        onTap: () {
                          _inputCtrl.text = q;
                          _focusNode.requestFocus();
                        }))
                    .toList(),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry, super.key});
  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            child: Text(message.isUser ? 'You' : 'Researcher',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                    letterSpacing: 0.3,
                    fontFamily: 'GeneralSans')),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primaryText
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 1),
              ),
              child: Text(message.content,
                  style: TextStyle(
                      fontSize: 14,
                      color: message.isUser
                          ? AppColors.background
                          : AppColors.primaryText,
                      height: 1.55,
                      fontFamily: 'GeneralSans')),
            ),
          ),
          if (!message.isUser && message.citations != null) ...[
            const SizedBox(height: 10),
            ...message.citations!.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CitationTile(
                      index: c.id, title: c.title, url: c.url),
                )),
          ],
          if (!message.isUser && message.isError && onRetry != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase =
                  ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
              final op =
                  (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2)
                      .clamp(0.3, 1.0);
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                child: Opacity(
                  opacity: op,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.mutedText,
                        shape: BoxShape.circle),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                fontFamily: 'GeneralSans')),
      ),
    );
  }
}
