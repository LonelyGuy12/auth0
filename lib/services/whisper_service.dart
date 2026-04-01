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

  /// Returns true if the microphone permission is available.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording audio to a temp file.
  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/whisper_input.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
      ),
      path: _recordingPath!,
    );
    return true;
  }

  /// Stops recording and transcribes via Groq Whisper. Returns the transcript.
  Future<String?> stopAndTranscribe() async {
    final path = await _recorder.stop();
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    try {
      final uri = Uri.parse(
          'https://api.groq.com/openai/v1/audio/transcriptions');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${AppConstants.groqApiKey}'
        ..fields['model'] = 'whisper-large-v3-turbo'
        ..fields['response_format'] = 'text'
        ..fields['language'] = 'en'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: 'audio.m4a',
        ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final transcript = response.body.trim();
        // Clean up temp file
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
    _recorder.dispose();
  }
}
