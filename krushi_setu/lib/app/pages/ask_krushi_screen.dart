import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/services/voice_chat_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:krushi_setu/app/widgets/language_selector.dart';

enum MessageType { user, ai }

class ChatMessage {
  final MessageType type;
  String text;
  final DateTime timestamp;
  bool isComplete;

  ChatMessage({
    required this.type,
    required this.text,
    required this.timestamp,
    this.isComplete = true,
  });
}

class AskKrushiScreen extends StatefulWidget {
  const AskKrushiScreen({super.key});

  @override
  State<AskKrushiScreen> createState() => _AskKrushiScreenState();
}

class _AskKrushiScreenState extends State<AskKrushiScreen>
    with TickerProviderStateMixin {
  // Voice service
  final VoiceChatService _voiceService = VoiceChatService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  // State
  String _selectedLanguage = 'Kannada';
  
  final List<ChatMessage> _messages = [];
  bool _isMicPressed = false;
  bool _isThinking = false;
  String _thinkingMessage = '';
  String _lastIntent = '';

  // Audio playback queue
  final List<Uint8List> _audioQueue = [];
  bool _isPlayingAudio = false;

  // Animations
  late AnimationController _waveController;
  late AnimationController _pulseController;

  // Stream subscriptions
  StreamSubscription? _transcriptSub;
  StreamSubscription? _aiTextSub;
  StreamSubscription? _audioSub;
  StreamSubscription? _thinkingSub;
  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _setupListeners();
    
    // Connect to websocket eagerly but wait for transition
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _initSession();
      }
    });
  }


  void _setupListeners() {
    _transcriptSub = _voiceService.transcriptStream.listen((text) {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.type == MessageType.user && !_messages.last.isComplete) {
            _messages.last.text = text;
          } else {
            if (_messages.isNotEmpty && _messages.last.type == MessageType.ai) {
              _messages.last.isComplete = true;
            }
            _messages.add(ChatMessage(
              type: MessageType.user,
              text: text,
              timestamp: DateTime.now(),
              isComplete: false,
            ));
          }
        });
        _scrollToBottom();
      }
    });

    _aiTextSub = _voiceService.aiTextStream.listen((text) {
      if (mounted && text.trim().isNotEmpty) {
        setState(() {
          _isThinking = false;  // Stop thinking when AI text arrives
          if (_messages.isNotEmpty && _messages.last.type == MessageType.user) {
            _messages.last.isComplete = true;
          }
          if (_messages.isNotEmpty && _messages.last.type == MessageType.ai && !_messages.last.isComplete) {
            _messages.last.text += _messages.last.text.isEmpty ? text : ' $text';
          } else {
            _messages.add(ChatMessage(
              type: MessageType.ai,
              text: text,
              timestamp: DateTime.now(),
              isComplete: false,
            ));
          }
        });
        _scrollToBottom();
      }
    });

    _audioSub = _voiceService.audioStream.listen((audioBytes) {
      _audioQueue.add(audioBytes);
      _playNextAudio();
    });

    _thinkingSub = _voiceService.thinkingStream.listen((message) {
      if (mounted) {
        setState(() {
          _isThinking = true;
          _thinkingMessage = _getThinkingText(message);
        });
        _scrollToBottom();
      }
    });

    _intentSub = _voiceService.intentStream.listen((data) {
      if (mounted) {
        setState(() {
          _lastIntent = data['intent'] as String? ?? '';
          // Once we get intent info, thinking is about to end
        });
      }
    });
  }

  String _getThinkingText(String message) {
    switch (message) {
      case 'understanding':
        return 'Understanding your question...';
      case 'weather':
        return 'Checking weather data...';
      case 'pest_disease':
        return 'Looking up crop health info...';
      case 'fertilizer':
        return 'Checking fertilizer guidance...';
      case 'irrigation':
        return 'Checking irrigation advice...';
      case 'context':
        return 'Loading your farm details...';
      case 'generating':
        return 'Generating response...';
      default:
        return 'Thinking...';
    }
  }
  
  Future<void> _initSession() async {
    await _voiceService.startSession(language: _selectedLanguage);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _playNextAudio() async {
    if (_isPlayingAudio || _audioQueue.isEmpty) return;
    
    setState(() {
       _isPlayingAudio = true;
    });

    while (_audioQueue.isNotEmpty) {
      final audioBytes = _audioQueue.removeAt(0);
      try {
        await _audioPlayer.play(BytesSource(audioBytes));
        
        // Add a fallback timeout based on audio length to prevent hanging forever
        // 16kHz PCM audio = ~32 bytes per millisecond
        final estimatedDuration = Duration(milliseconds: (audioBytes.length / 32).ceil() + 2000);
        
        await Future.any([
          _audioPlayer.onPlayerComplete.first,
          Future.delayed(estimatedDuration),
        ]);
      } catch (e) {
        debugPrint('Audio playback error: $e');
      }
    }

    if (mounted) {
      setState(() {
         _isPlayingAudio = false;
         if (_messages.isNotEmpty && _messages.last.type == MessageType.ai) {
           _messages.last.isComplete = true;
         }
      });
    }
  }

  @override
  void dispose() {
    _transcriptSub?.cancel();
    _aiTextSub?.cancel();
    _audioSub?.cancel();
    _thinkingSub?.cancel();
    _intentSub?.cancel();
    _scrollController.dispose();
    _voiceService.dispose();
    _audioPlayer.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        extendBody: true,

        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
              //   child: _buildStatusBanner(),
              // ),
              Expanded(
                child: _messages.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F8F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'How can I help you today?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Text(
                              'Ask Maya about crop diseases, weather, or farming techniques.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      itemCount: _messages.length + (_isThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show thinking indicator at the end
                        if (_isThinking && index == _messages.length) {
                          return _buildThinkingBubble();
                        }
                        final msg = _messages[index];
                        if (msg.type == MessageType.user) {
                          return _buildUserBubble(msg);
                        } else {
                          return _buildKrushiBubble(msg);
                        }
                      },
                  ),
              ),
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_voiceService.isSessionActive) {
                await _voiceService.endSession();
              }
              if (mounted) Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Color(0xFF2E7D32), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask Krushi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Your AI farming assistant',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return LanguageSelectorWidget(
      selectedLanguage: _selectedLanguage,
      onLanguageChanged: (value) {
        setState(() {
          _selectedLanguage = value;
        });
        if (_voiceService.isSessionActive) {
          _voiceService.endSession().then((_) {
            _initSession();
          });
        }
      },
    );
  }

  // ─── Chat Bubbles ──────────────────────────────────────────

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Widget _buildUserBubble(ChatMessage message) {
    final timeStr = _formatTime(message.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topRight: Radius.circular(4),
                ),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppColors.primary, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You • $timeStr',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKrushiBubble(ChatMessage message) {
    final timeStr = _formatTime(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, right: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  topLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F8F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Krushi • $timeStr',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Thinking Indicator ────────────────────────────────────

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, right: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  topLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE8F5E9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _thinkingMessage.isEmpty ? 'Thinking...' : _thinkingMessage,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Mic Area ───────────────────────────────────────

  Widget _buildBottomArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
            ),
            child: Column(
              children: [
                const Text(
                  'Press and hold to talk',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Release to send',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDotWave(),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTapDown: _isPlayingAudio ? null : (_) async {
                        setState(() {
                          _isMicPressed = true;
                        });
                        await _voiceService.startRecording();
                      },
                      onTapUp: _isPlayingAudio ? null : (_) async {
                        setState(() {
                          _isMicPressed = false;
                        });
                        await _voiceService.stopRecording();
                      },
                      onTapCancel: _isPlayingAudio ? null : () async {
                        setState(() {
                          _isMicPressed = false;
                        });
                        await _voiceService.stopRecording();
                      },
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = _isMicPressed ? 1.0 + (_pulseController.value * 0.08) : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: _isMicPressed 
                                        ? AppColors.primary.withValues(alpha: 0.3) 
                                        : Colors.black.withValues(alpha: 0.05),
                                    blurRadius: _isMicPressed ? 20 : 10,
                                    spreadRadius: _isMicPressed ? 5 : 0,
                                  ),
                                  if (_isMicPressed)
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      blurRadius: 40,
                                      spreadRadius: 15,
                                    ),
                                ],
                                border: Border.all(
                                  color: _isPlayingAudio 
                                      ? Colors.grey.shade300 
                                      : (_isMicPressed ? AppColors.primary : Colors.grey.shade200),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.mic,
                                color: _isPlayingAudio 
                                    ? Colors.grey.shade400 
                                    : (_isMicPressed ? AppColors.primary : const Color(0xFF2E7D32)),
                                size: 38,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildDotWave(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDotWave() {
     return Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         _dot(opacity: 0.3),
         const SizedBox(width: 6),
         _dot(opacity: 0.6),
         const SizedBox(width: 6),
         _dot(opacity: 0.9),
         const SizedBox(width: 6),
         _dot(opacity: 0.6),
         const SizedBox(width: 6),
         _dot(opacity: 0.3),
       ],
     );
  }
  
  Widget _dot({required double opacity}) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
