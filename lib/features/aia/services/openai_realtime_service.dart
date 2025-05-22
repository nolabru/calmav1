import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:calma_flutter/features/aia/services/audio_service.dart';

class OpenAIRealtimeService {
  // URL da API da OpenAI para conversação em tempo real
  static const String _websocketUrl = "wss://api.openai.com/v1/realtime";
  
  // Obtém a chave da API do arquivo .env
  static String get _apiKey => "Bearer ${dotenv.env['OPENAI_API_KEY'] ?? ''}";
  
  // Modelo GPT-4o para conversação em tempo real
  static const String _model = "gpt-4o-realtime-preview";

  WebSocketChannel? _canal;
  String? _sessionId;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final void Function(Uint8List)? onAudioResponse;
  final VoidCallback? onConversationDone;

  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _conversaEncerrada = false;
  bool _aguardandoResposta = false;

  OpenAIRealtimeService({
    this.onAudioResponse,
    this.onConversationDone,
  }) {
    debugPrint('[AIA] Inicializando serviço com: URL=$_websocketUrl, Modelo=$_model');
  }

  Future<bool> iniciarConexaoComOpenAI() async {
    try {
      debugPrint('[AIA] Iniciando conexão com OpenAI...');
      
      // Verificando se a chave da API está definida
      if (_apiKey == "Bearer " || _apiKey.isEmpty) {
        debugPrint('[AIA] ❌ Chave da API não encontrada no arquivo .env');
        return false;
      }
      
      // Construindo a URL com parâmetros de consulta
      final uri = Uri.parse("$_websocketUrl?model=$_model");
      debugPrint('[AIA] Conectando a: ${uri.toString()}');

      // Tentando estabelecer conexão WebSocket
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
          'openai-beta': 'realtime=v1',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Tempo limite de conexão excedido');
      });
      
      debugPrint('[AIA] Conexão WebSocket estabelecida');
      
      _canal = IOWebSocketChannel(socket);
      _isConnected = true;
      _conversaEncerrada = false;

      _canal!.stream.listen(_processarMensagem, 
        onError: (e) {
          debugPrint('[AIA] WebSocket erro: $e');
        },
        onDone: () {
          debugPrint('[AIA] WebSocket conexão fechada');
          _isConnected = false;
        }
      );

      debugPrint('[AIA] Aguardando antes de enviar configuração...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      debugPrint('[AIA] Enviando configuração da sessão...');
      _enviarConfiguracaoDaSessao();

      debugPrint('[AIA] Abrindo player de áudio...');
      await _player.openPlayer();

      debugPrint('[AIA] Conexão inicializada com sucesso');
      return true;
    } catch (e) {
      debugPrint('[AIA] Erro ao conectar com a OpenAI: $e');
      if (e is SocketException) {
        debugPrint('[AIA] Erro de socket: ${e.message}, Endereço: ${e.address}, Porta: ${e.port}');
      }
      _isConnected = false;
      return false;
    }
  }

  void _enviarConfiguracaoDaSessao() {
    final payload = {
      "type": "session.update",
      "session": {
        "instructions": "Você é uma IA simpática e útil que responde em português do Brasil.",
        "turn_detection": {
          "type": "server_vad",
          "threshold": 0.5,
          "silence_duration_ms": 600,
          "prefix_padding_ms": 300,
          "create_response": true,
          "interrupt_response": false
        }
      }
    };
    
    final jsonPayload = jsonEncode(payload);
    debugPrint('[AIA] Enviando configuração: $jsonPayload');
    _canal!.sink.add(jsonPayload);
  }

  void _processarMensagem(dynamic mensagem) async {
    debugPrint('[AIA] Mensagem recebida: $mensagem');

    try {
      final data = jsonDecode(mensagem);
      final type = data['type'];

      switch (type) {
        case 'session.created':
          _sessionId = data['session']['id'];
          debugPrint('[AIA] Sessão criada: $_sessionId');
          _iniciarCapturaDeAudio();
          break;

        case 'session.error':
          debugPrint('[AIA] ❌ Erro na sessão: ${data['error']}');
          _conversaEncerrada = true;
          await AudioService.pararCapturaDeAudio();
          break;

        case 'response.audio.delta':
          final base64Audio = data['delta'];
          final audioBytes = base64Decode(base64Audio);

          debugPrint('[AIA] 🎧 Áudio da IA recebido (${audioBytes.length} bytes)');
          _aguardandoResposta = true;
          await AudioService.pararCapturaDeAudio();

          try {
            await _player.startPlayer(
              fromDataBuffer: audioBytes,
              codec: Codec.pcm16,
              sampleRate: 16000,
              numChannels: 1,
              whenFinished: () {
                debugPrint('[AIA] 🟢 Resposta concluída. Retomando escuta...');
                _aguardandoResposta = false;
                _iniciarCapturaDeAudio();
              },
            );
            
            onAudioResponse?.call(Uint8List.fromList(audioBytes));
          } catch (e) {
            debugPrint('[AIA] ❌ Erro ao reproduzir áudio: $e');
            _aguardandoResposta = false;
            _iniciarCapturaDeAudio();
          }
          break;

        case 'response.done':
          debugPrint('[AIA] ✅ Conversa encerrada');
          _conversaEncerrada = true;
          await AudioService.pararCapturaDeAudio();
          onConversationDone?.call();
          break;

        case 'error':
          debugPrint('[AIA] ❌ Erro recebido: ${data['message']}');
          break;

        default:
          debugPrint('[AIA] Tipo desconhecido: $type');
          break;
      }
    } catch (e) {
      debugPrint('[AIA] Erro ao processar mensagem: $e');
      if (e is FormatException) {
        debugPrint('[AIA] Erro de formato: ${e.message}, Fonte: ${e.source}');
      }
    }
  }

  void _iniciarCapturaDeAudio() {
    if (_conversaEncerrada || _aguardandoResposta) {
      debugPrint('[AIA] Ignorando início da captura. aguardando=$_aguardandoResposta encerrada=$_conversaEncerrada');
      return;
    }

    debugPrint('[AIA] 🎙️ Iniciando captura de áudio');
    AudioService.iniciarCapturaDeAudio((Uint8List buffer) {
      if (_aguardandoResposta || _conversaEncerrada || !_isConnected) return;

      if (buffer.isNotEmpty && _isConnected) {
        try {
          final base64Audio = base64Encode(buffer);
          // Formato correto para a API da OpenAI
          final payload = {
            "type": "input_audio_buffer.append",
            "audio": base64Audio,
          };
          final jsonPayload = jsonEncode(payload);
          debugPrint('[AIA] Enviando payload: $jsonPayload');
          _canal!.sink.add(jsonPayload);
          debugPrint('[AIA] Enviando buffer: ${buffer.length} bytes');
        } catch (e) {
          debugPrint('[AIA] ❌ Erro ao enviar buffer de áudio: $e');
        }
      }
    });
  }

  void encerrarConversa() async {
    debugPrint('[AIA] Encerrando conversa...');
    _conversaEncerrada = true;
    
    try {
      await AudioService.pararCapturaDeAudio();
      
      if (_player.isPlaying) {
        await _player.stopPlayer();
      }
      
      await _player.closePlayer();
      
      if (_canal != null) {
        _canal?.sink.close();
        _canal = null;
      }
      
      _isConnected = false;
      debugPrint('[AIA] Conversa encerrada com sucesso');
    } catch (e) {
      debugPrint('[AIA] ❌ Erro ao encerrar conversa: $e');
    }
  }
}
