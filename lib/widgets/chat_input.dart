import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/chat_provider.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF0A0A0A),
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final isLoading = chat.isLoading;
        return Container(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            border: Border(
              top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mic button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3291FF).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: _isListening
                      ? const Color(0xFF3291FF)
                      : const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  elevation: _isListening ? 4 : 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isLoading ? null : _toggleVoiceInput,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isListening
                              ? const Color(0xFF3291FF)
                              : const Color(0xFF1A1A1A),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Colors.white
                            : const Color(0xFF666666),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text input
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _send();
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !isLoading,
                    maxLines: 5,
                    minLines: 1,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 14,
                      letterSpacing: -0.2,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: isLoading ? 'Thinking...' : 'Send a message...',
                      hintStyle: const TextStyle(color: Color(0xFF666666)),
                      filled: true,
                      fillColor: const Color(0xFF000000),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF3291FF), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isLoading && _controller.text.trim().isNotEmpty
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: isLoading || _controller.text.trim().isEmpty
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  elevation: isLoading || _controller.text.trim().isEmpty ? 0 : 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isLoading || _controller.text.trim().isEmpty ? null : _send,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: isLoading || _controller.text.trim().isEmpty
                            ? const Color(0xFF666666)
                            : Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
