import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../config/constants.dart';

class WhisperService {
  static final WhisperService _instance = WhisperService._internal();
  factory WhisperService() => _instance;
  WhisperService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  Timer? _silenceTimer;
  Timer? _amplitudePollTimer;

  /// Amplitude below this (dBFS) = silence.
  static const double _silenceThreshold = -38.0;

  /// How long continuous silence triggers auto-stop.
  static const Duration _silenceDuration = Duration(seconds: 2);

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording. Calls [onSilenceDetected] after [_silenceDuration]
  /// of continuous silence.
  Future<bool> startRecording(
      {required void Function() onSilenceDetected}) async {
    if (!await _recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/whisper_input.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
      ),
      path: _recordingPath!,
    );

    // Skip the first second to avoid false-positive silence at recording start
    await Future.delayed(const Duration(seconds: 1));

    // Poll amplitude every 200ms to detect silence
    _amplitudePollTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) async {
        if (!await _recorder.isRecording()) return;
        final amp = await _recorder.getAmplitude();

        if (amp.current < _silenceThreshold) {
          _silenceTimer ??= Timer(_silenceDuration, () {
            _silenceTimer = null;
            onSilenceDetected();
          });
        } else {
          // Voice still active — reset silence timer
          _silenceTimer?.cancel();
          _silenceTimer = null;
        }
      },
    );

    return true;
  }

  /// Stops recording and transcribes via Groq Whisper.
  Future<String?> stopAndTranscribe() async {
    _amplitudePollTimer?.cancel();
    _amplitudePollTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;

    final path = await _recorder.stop();
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    try {
      final uri =
          Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${AppConstants.groqApiKey}'
        ..fields['model'] = 'whisper-large-v3-turbo'
        ..fields['response_format'] = 'text'
        ..fields['language'] = 'en'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: 'audio.wav',
        ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final transcript = response.body.trim();
        await file.delete().catchError((_) => file);
        return transcript.isEmpty ? null : transcript;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isRecording => _recorder.isRecording();

  void dispose() {
    _amplitudePollTimer?.cancel();
    _silenceTimer?.cancel();
    _recorder.dispose();
  }
}
