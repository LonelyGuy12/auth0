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

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  // Pulse animation for the mic button when listening
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed && _isListening) {
          _pulseController.forward();
        }
      });

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
        _pulseController.stop();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
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

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
      return;
    }

    // Re-init if needed
    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            _pulseController.stop();
            _pulseController.reset();
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
    _pulseController.forward();

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          // Stop listening
          setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
          // Auto-send
          _send();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Listening indicator banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isListening
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulsingDot(),
                            const SizedBox(width: 8),
                            const Text(
                              'Listening...',
                              style: TextStyle(
                                color: Color(0xFF3291FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap mic to stop',
                              style: TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mic button with pulse
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3291FF).withValues(alpha: 0.5),
                              blurRadius: 24,
                              spreadRadius: 3,
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
                      hintText: _isListening
                          ? 'Listening...'
                          : isLoading
                              ? 'Thinking...'
                              : 'Send a message...',
                      hintStyle: TextStyle(
                        color: _isListening
                            ? const Color(0xFF3291FF)
                            : const Color(0xFF666666),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF000000),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1A1A1A), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isListening
                              ? const Color(0xFF3291FF).withValues(alpha: 0.4)
                              : const Color(0xFF1A1A1A),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF3291FF), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isLoading && _controller.text.trim().isNotEmpty
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
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
                  elevation:
                      isLoading || _controller.text.trim().isEmpty ? 0 : 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isLoading || _controller.text.trim().isEmpty
                        ? null
                        : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.all(16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: RotationTransition(
                              turns: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          key: ValueKey(isLoading || _controller.text.trim().isEmpty),
                          color: isLoading || _controller.text.trim().isEmpty
                              ? const Color(0xFF666666)
                              : Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),         // close Row
            ],
          ),         // close Column
        );
      },
    );
  }
}

/// A small dot that pulses between blue and dim to indicate active listening.
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF3291FF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
