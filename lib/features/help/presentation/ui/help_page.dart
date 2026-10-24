import 'package:flutter/material.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/core/theme/app_colors.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/repositories/ai_help_repository.dart';

class HelpPage extends StatefulWidget {
  final AiHelpRepository repository;

  const HelpPage({super.key, required this.repository});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.auto_awesome_rounded, size: 19),
          ),
          const SizedBox(width: 10),
          Text(context.tr(LanguageKeys.aiAssistant)),
        ],
      ),
    ),
    body: Column(
      children: [
        if (!widget.repository.isConfigured)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(context.tr(LanguageKeys.aiSetupRequired)),
          ),
        Expanded(
          child: _messages.isEmpty
              ? _WelcomeMessage(text: context.tr(LanguageKeys.aiWelcome))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _TypingBubble(
                        text: context.tr(LanguageKeys.aiThinking),
                      );
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: context.tr(LanguageKeys.askAnything),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    if (!widget.repository.isConfigured) {
      _message(LanguageKeys.aiSetupRequired);
      return;
    }
    final history = List<AiMessage>.from(_messages);
    setState(() {
      _messages.add(AiMessage(text: question, isUser: true));
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();
    try {
      final answer = await widget.repository.ask(
        question: question,
        history: history,
      );
      if (mounted) {
        setState(() => _messages.add(AiMessage(text: answer, isUser: false)));
      }
    } catch (_) {
      if (mounted) _message(LanguageKeys.aiUnavailable);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _message(String key) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr(key))));
  }
}

class _WelcomeMessage extends StatelessWidget {
  final String text;

  const _WelcomeMessage({required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 58, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  final AiMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 330),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser
            ? AppColors.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: message.isUser ? const Radius.circular(4) : null,
          bottomLeft: message.isUser ? null : const Radius.circular(4),
        ),
        border: message.isUser
            ? null
            : Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: message.isUser
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          height: 1.45,
        ),
      ),
    ),
  );
}

class _TypingBubble extends StatelessWidget {
  final String text;

  const _TypingBubble({required this.text});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(color: Color(0xFF718078))),
    ),
  );
}
