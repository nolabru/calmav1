// ===============================
// FILE: openai_realtime_service.dart
// ===============================
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:calma_flutter/features/aia/services/audio_service.dart';

class OpenAIRealtimeService {
  static const String _websocketUrl = "wss://api.openai.com/v1/realtime";
  static const String _apiKey = "Bearer sk-..."; // Insira sua chave da OpenAI
  static const String _model = "gpt-4o-realtime-preview";

  WebSocketChannel? _canal;
  String? _sessionId;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final void Function(String)? onTextResponse;
  final void Function(Uint8List)? onAudioResponse;
  final VoidCallback? onConversationDone;

  int _appendCount = 0;

  OpenAIRealtimeService({
    this.onTextResponse,
    this.onAudioResponse,
    this.onConversationDone,
  });

  /// Inicia a conexão WebSocket com a API da OpenAI e configura a sessão.
  Future<bool> iniciarConexaoComOpenAI() async {
    try {
      final uri = Uri.parse("$_websocketUrl?model=$_model");

      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
          'openai-beta': 'realtime=v1',
        },
      );

      _canal = IOWebSocketChannel(socket);
      _isConnected = true;

      _canal!.stream.listen(_processarMensagem, onError: (e) {
        debugPrint('Erro WebSocket: $e');
      });

      await Future.delayed(const Duration(milliseconds: 300));

      _enviarConfiguracaoDaSessao();

      return true;
    } catch (e) {
      debugPrint('Erro ao conectar com a OpenAI: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Envia as configurações iniciais da sessão.
  void _enviarConfiguracaoDaSessao() {
    final payload = {
      "type": "session.update",
      "session": {
        "voice": "alloy",
        "instructions": "Você é uma IA simpática e útil.",
        "input_modality": "audio",
        "output_modality": ["text", "audio"]
      }
    };

    _canal!.sink.add(jsonEncode(payload));
  }

  /// Processa mensagens recebidas do WebSocket.
  void _processarMensagem(dynamic mensagem) {
    try {
      final data = jsonDecode(mensagem);
      final type = data['type'];

      switch (type) {
        case 'session.created':
          _sessionId = data['session']['id'];
          _iniciarCapturaDeAudio();
          break;
        case 'response.text.delta':
          final text = data['delta'];
          if (text != null && onTextResponse != null) {
            onTextResponse!(text);
          }
          break;
        case 'response.audio.delta':
          final base64Audio = data['delta'];
          final audioBytes = base64Decode(base64Audio);
          onAudioResponse?.call(Uint8List.fromList(audioBytes));
          break;
        case 'response.done':
          onConversationDone?.call();
          break;
      }
    } catch (e) {
      debugPrint('Erro ao processar mensagem da IA: $e');
    }
  }

  /// Inicia a captura de áudio e envia os buffers para a API.
  void _iniciarCapturaDeAudio() {
    AudioService.iniciarCapturaDeAudio((Uint8List buffer) {
      _enviarAudio(buffer);
    });
  }

  /// Envia o buffer de áudio codificado em Base64 para o WebSocket da OpenAI.
  void _enviarAudio(Uint8List buffer) {
    if (_sessionId == null || !_isConnected) return;

    final payload = {
      "type": "input_audio_buffer.append",
      "session": {"session_id": _sessionId},
      "data": {"audio": base64Encode(buffer)}
    };

    _canal!.sink.add(jsonEncode(payload));

    _appendCount++;
    if (_appendCount >= 5) {
      _canal!.sink.add(jsonEncode({
        "type": "input_audio_buffer.commit",
        "session": {"session_id": _sessionId}
      }));
      _appendCount = 0;
    }
  }

  /// Finaliza a conversa e encerra a captura de áudio.
  void encerrarConversa() {
    AudioService.pararCapturaDeAudio();
    _canal?.sink.close();
    _canal = null;
    _isConnected = false;
  }
}
