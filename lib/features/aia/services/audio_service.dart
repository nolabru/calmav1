import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static MediaStream? _localStream;
  static MediaStreamTrack? _audioTrack;
  static bool _isCapturing = false;
  static bool _isInitialized = false;

  static bool get isCapturing => _isCapturing;

  static Future<bool> solicitarPermissaoMicrofone() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('[AudioService] Permissão de microfone negada');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[AudioService] Erro ao solicitar permissão de microfone: $e');
      return false;
    }
  }

  static Future<bool> iniciarCapturaDeAudio(void Function(List<int>) onAudioData) async {
    try {
      if (_isCapturing) {
        debugPrint('[AudioService] Já está capturando áudio');
        return true;
      }

      // Parar qualquer captura anterior
      await pararCapturaDeAudio();

      debugPrint('[AudioService] Iniciando captura de áudio via WebRTC');
      
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      if (_localStream == null) {
        debugPrint('[AudioService] Falha ao obter stream de áudio');
        return false;
      }
      
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isEmpty) {
        debugPrint('[AudioService] Nenhuma faixa de áudio disponível');
        return false;
      }
      
      _audioTrack = audioTracks.first;
      _audioTrack!.enabled = true;
      
      debugPrint('[AudioService] Captura de áudio iniciada com sucesso');
      _isCapturing = true;
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[AudioService] Erro ao iniciar captura de áudio via WebRTC: $e');
      return false;
    }
  }

  static Future<void> pararCapturaDeAudio() async {
    if (!_isCapturing && _localStream == null) {
      return;
    }

    debugPrint('[AudioService] Parando captura de áudio');
    _isCapturing = false;

    try {
      if (_audioTrack != null) {
        _audioTrack!.enabled = false;
        _audioTrack!.stop();
        _audioTrack = null;
      }
      
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
        await _localStream!.dispose();
        _localStream = null;
      }
      
      debugPrint('[AudioService] Captura de áudio parada com sucesso');
    } catch (e) {
      debugPrint('[AudioService] Erro ao parar captura de áudio: $e');
    }
  }

  static MediaStreamTrack? getAudioTrack() => _audioTrack;
  static MediaStream? getMediaStream() => _localStream;
  
  // Método para mutar o áudio
  static void muteAudio() {
    if (_audioTrack != null) {
      debugPrint('[AudioService] Mutando áudio');
      _audioTrack!.enabled = false;
    }
  }
  
  // Método para desmutar o áudio
  static void unmuteAudio() {
    if (_audioTrack != null) {
      debugPrint('[AudioService] Desmutando áudio');
      _audioTrack!.enabled = true;
    }
  }
}
