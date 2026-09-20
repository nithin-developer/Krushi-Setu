import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:record/record.dart';
import 'package:krushi_setu/core/constants/app_constants.dart';
import 'package:krushi_setu/core/storage/local_storage.dart';

/// Voice session states matching the backend protocol
enum VoiceState { idle, connecting, listening, processing, speaking }

/// Represents a message from the voice backend
class VoiceMessage {
  final String type;
  final String? text;
  final String? audioData; // base64 encoded WAV
  final String? state;
  final bool? isFinal;
  final String? error;

  VoiceMessage({
    required this.type,
    this.text,
    this.audioData,
    this.state,
    this.isFinal,
    this.error,
  });

  factory VoiceMessage.fromJson(Map<String, dynamic> json) {
    return VoiceMessage(
      type: json['type'] as String? ?? '',
      text: json['text'] as String?,
      audioData: json['data'] as String?,
      state: json['state'] as String?,
      isFinal: json['is_final'] as bool?,
      error: json['message'] as String?,
    );
  }
}

/// Service that manages the full voice chat pipeline:
/// Mic recording → WebSocket → Backend → STT → LLM → TTS → Audio playback
class VoiceChatService {
  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _recordSubscription;
  StreamSubscription? _wsSubscription;

  // State
  VoiceState _state = VoiceState.idle;
  bool _isSessionActive = false;
  bool _isRecording = false;
  String _selectedLanguage = 'Kannada';

  // Stream controllers for UI updates
  final _stateController = StreamController<VoiceState>.broadcast();
  final _transcriptController = StreamController<String>.broadcast();
  final _aiTextController = StreamController<String>.broadcast();
  final _audioController = StreamController<Uint8List>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _thinkingController = StreamController<String>.broadcast();
  final _intentController = StreamController<Map<String, dynamic>>.broadcast();
  // Public streams
  Stream<VoiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get aiTextStream => _aiTextController.stream;
  Stream<Uint8List> get audioStream => _audioController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get thinkingStream => _thinkingController.stream;
  Stream<Map<String, dynamic>> get intentStream => _intentController.stream;

  VoiceState get currentState => _state;
  bool get isSessionActive => _isSessionActive;
  bool get isRecording => _isRecording;
  String get selectedLanguage => _selectedLanguage;

  /// Start a voice chat session
  Future<bool> startSession({String language = 'Kannada'}) async {
    if (_isSessionActive) return true;

    _selectedLanguage = language;
    _setState(VoiceState.connecting);

    try {
      // Check mic permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _errorController.add('Microphone permission denied');
        _setState(VoiceState.idle);
        return false;
      }

      // Connect WebSocket
      final token = LocalStorage.accessToken ?? '';
      final wsUrl = '${AppConstants.wsUrl}/voice/ws?token=$token';
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: const Duration(seconds: 20),
      );

      // Listen for backend messages
      _wsSubscription = _channel!.stream.listen(
        _handleServerMessage,
        onError: (error) {
          _errorController.add('Connection error: $error');
          _setState(VoiceState.idle);
          _isSessionActive = false;
        },
        onDone: () {
          _isSessionActive = false;
          _setState(VoiceState.idle);
        },
      );

      // Send session_start
      _sendJson({
        'type': 'session_start',
        'language': language,
      });

      _isSessionActive = true;
      return true;
    } catch (e) {
      _errorController.add('Failed to start session: $e');
      _setState(VoiceState.idle);
      return false;
    }
  }

  /// Stop the voice chat session
  Future<void> endSession() async {
    if (!_isSessionActive) return;

    try {
      await stopRecording();

      _sendJson({'type': 'session_end'});

      await Future.delayed(const Duration(milliseconds: 200));
      await _channel?.sink.close();
    } catch (_) {}

    _wsSubscription?.cancel();
    _channel = null;
    _isSessionActive = false;
    _setState(VoiceState.idle);
  }


  /// Signal end of speech manually
  void signalSpeechEnd() {
    _sendJson({'type': 'speech_end'});
  }

  /// Start recording from microphone for a push-to-talk turn
  Future<void> startRecording() async {
    if (!_isSessionActive || _isRecording) return;
    _isRecording = true;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _errorController.add('Microphone permission denied');
        _isRecording = false;
        return;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _recordSubscription = stream.listen(
        (data) {
          if (_isSessionActive && _channel != null) {
            _channel!.sink.add(data);
          }
        },
        onError: (e) {
          _errorController.add('Mic error: $e');
          _isRecording = false;
        },
        onDone: () {
          _isRecording = false;
        },
      );
    } catch (e) {
      _errorController.add('Microphone error: $e');
      _isRecording = false;
    }
  }

  /// Stop microphone recording for current turn
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;

    try {
      await _recordSubscription?.cancel();
      _recordSubscription = null;
      await _recorder.stop();
    } catch (_) {}

    signalSpeechEnd();
  }

  /// Handle incoming WebSocket messages from the backend
  void _handleServerMessage(dynamic message) {
    if (message is String) {
      try {
        final data = jsonDecode(message) as Map<String, dynamic>;
        final voiceMsg = VoiceMessage.fromJson(data);

        switch (voiceMsg.type) {
          case 'session_ready':
            _setState(VoiceState.listening);
            break;

          case 'transcript':
            if (voiceMsg.text != null && voiceMsg.text!.isNotEmpty) {
              _transcriptController.add(voiceMsg.text!);
            }
            break;

          case 'ai_text':
            if (voiceMsg.text != null && voiceMsg.text!.isNotEmpty) {
              _aiTextController.add(voiceMsg.text!);
            }
            break;

          case 'audio':
            if (voiceMsg.audioData != null) {
              final audioBytes = base64Decode(voiceMsg.audioData!);
              _audioController.add(Uint8List.fromList(audioBytes));
            }
            break;

          case 'state':
            if (voiceMsg.state != null) {
              switch (voiceMsg.state) {
                case 'listening':
                  _setState(VoiceState.listening);
                  break;
                case 'processing':
                  _setState(VoiceState.processing);
                  break;
                case 'speaking':
                  _setState(VoiceState.speaking);
                  break;
                case 'idle':
                  _setState(VoiceState.idle);
                  break;
              }
            }
            break;


          case 'thinking':
            if (data['message'] != null) {
              _thinkingController.add(data['message'] as String);
            }
            break;

          case 'intent':
            _intentController.add({
              'intent': data['intent'] ?? 'general',
              'confidence': data['confidence'] ?? 0.0,
            });
            break;

          case 'error':
            _errorController.add(voiceMsg.error ?? 'Unknown error');
            break;
        }
      } catch (e) {
        // Non-JSON or parse error
      }
    }
  }

  /// Send a JSON message to the backend
  void _sendJson(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Update internal state and notify listeners
  void _setState(VoiceState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Clean up all resources
  void dispose() {
    _recordSubscription?.cancel();
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _recorder.dispose();
    _stateController.close();
    _transcriptController.close();
    _aiTextController.close();
    _audioController.close();
    _errorController.close();
    _thinkingController.close();
    _intentController.close();
  }
}
