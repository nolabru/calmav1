import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static bool _isInitialized = false;
  static bool _isCapturing = false;
  static StreamController<Uint8List>? _streamController;

  static bool get isRecording => _recorder.isRecording;

  static Future<bool> solicitarPermissaoMicrofone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<void> _inicializarRecorder() async {
    if (!_isInitialized) {
      await _recorder.openRecorder();
      _isInitialized = true;
    }
  }

  static Future<bool> iniciarCapturaDeAudio(
    void Function(Uint8List buffer) onAudioData,
  ) async {
    try {
      await _inicializarRecorder();

      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }

      _streamController = StreamController<Uint8List>();
      _isCapturing = true;

      await _recorder.startRecorder(
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
        audioSource: AudioSource.microphone,
        toStream: _streamController!.sink,
      );

      _streamController!.stream.listen((buffer) {
        if (_isCapturing && buffer.isNotEmpty) {
          onAudioData(buffer);
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> pararCapturaDeAudio() async {
    _isCapturing = false;

    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }

    await _streamController?.close();
    _streamController = null;
  }
}
