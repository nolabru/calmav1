// ===============================
// FILE: audio_service.dart
// ===============================
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static bool _isInitialized = false;
  static StreamController<Uint8List>? _streamController;

  static bool get isRecording => _recorder.isRecording;

  /// Solicita a permissão de uso do microfone ao usuário.
  static Future<bool> solicitarPermissaoMicrofone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Inicializa o gravador de áudio, se necessário.
  static Future<void> _inicializarRecorder() async {
    if (!_isInitialized) {
      await _recorder.openRecorder();
      _isInitialized = true;
    }
  }

  /// Inicia a captura de áudio em tempo real e envia os buffers para o callback fornecido.
  static Future<bool> iniciarCapturaDeAudio(
    void Function(Uint8List buffer) onAudioData,
  ) async {
    try {
      await _inicializarRecorder();

      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }

      _streamController = StreamController<Uint8List>();

      await _recorder.startRecorder(
        codec: Codec.pcm16, // formato cru PCM 16-bit
        sampleRate: 16000, // exigido pela OpenAI
        numChannels: 1, // mono
        audioSource: AudioSource.microphone,
        toStream: _streamController!.sink,
      );

      _streamController!.stream.listen((buffer) {
        if (buffer.isNotEmpty) {
          onAudioData(buffer);
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Para a captura de áudio e libera os recursos.
  static Future<void> pararCapturaDeAudio() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }

    await _streamController?.close();
    _streamController = null;
  }
}
