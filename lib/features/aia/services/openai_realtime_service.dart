import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:calma_flutter/features/aia/services/audio_service.dart';

class OpenAIRealtimeService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final VoidCallback? onListeningStarted;
  final VoidCallback? onConversationDone;
  final void Function(Uint8List)? onAudioResponse;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  bool _isProcessingConnection = false;

  // Configuração de ICE servers para WebRTC
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan'
  };

  OpenAIRealtimeService({
    this.onListeningStarted,
    this.onConversationDone,
    this.onAudioResponse,
  });

  Future<bool> iniciarConexaoComOpenAI() async {
    if (_isProcessingConnection) {
      debugPrint('[AIA] Já existe uma conexão em andamento');
      return false;
    }

    _isProcessingConnection = true;

    try {
      // Limpar qualquer conexão anterior
      await encerrarConversa();

      debugPrint('[AIA] Criando conexão WebRTC...');
      _peerConnection = await createPeerConnection(_configuration);

      // Configurar eventos de conexão
      _configurarEventosDeConexao();

      // Configurar canal de dados para eventos
      await _configurarCanalDeDados();

      // Capturar e adicionar áudio local
      final success = await _configurarAudioLocal();
      if (!success) {
        debugPrint('[AIA] Falha ao configurar áudio local');
        _isProcessingConnection = false;
        return false;
      }

      // Criar e enviar oferta SDP
      final success2 = await _criarEEnviarOferta();
      if (!success2) {
        debugPrint('[AIA] Falha ao criar e enviar oferta SDP');
        _isProcessingConnection = false;
        return false;
      }

      _isConnected = true;
      _isProcessingConnection = false;
      onListeningStarted?.call();
      return true;
    } catch (e) {
      debugPrint("[AIA] Erro ao iniciar conexão WebRTC: $e");
      _isProcessingConnection = false;
      return false;
    }
  }

  void _configurarEventosDeConexao() {
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('[AIA] ICE Connection State: ${state.toString()}');
      
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        debugPrint('[AIA] WebRTC conectado com sucesso');
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
                state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
                state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        debugPrint('[AIA] WebRTC desconectado: ${state.toString()}');
        _isConnected = false;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      debugPrint('[AIA] ICE Candidate: ${candidate.candidate}');
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      debugPrint('[AIA] Faixa remota recebida: ${event.track.kind}');
      
      if (event.track.kind == 'audio') {
        _remoteStream = event.streams[0];
        debugPrint('[AIA] Áudio remoto recebido e configurado para reprodução');
      }
    };
  }

  Future<void> _configurarCanalDeDados() async {
    final dcInit = RTCDataChannelInit();
    dcInit.ordered = true;
    
    _dataChannel = await _peerConnection!.createDataChannel("oai-events", dcInit);
    
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      _processarMensagem(message.text);
    };
    
    _dataChannel!.onDataChannelState = (RTCDataChannelState state) {
      debugPrint('[AIA] Estado do canal de dados: ${state.toString()}');
      
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        debugPrint('[AIA] Canal de dados aberto, enviando configuração');
        _enviarConfiguracao();
      }
    };
  }

  Future<bool> _configurarAudioLocal() async {
    try {
      final success = await AudioService.iniciarCapturaDeAudio((_) {});
      if (!success) return false;

      _localStream = AudioService.getMediaStream();
      if (_localStream == null) {
        debugPrint('[AIA] Falha ao obter stream de áudio local');
        return false;
      }

      for (var track in _localStream!.getAudioTracks()) {
        debugPrint('[AIA] Adicionando faixa de áudio: ${track.id}');
        await _peerConnection!.addTrack(track, _localStream!);
      }
      
      return true;
    } catch (e) {
      debugPrint('[AIA] Erro ao configurar áudio local: $e');
      return false;
    }
  }

  Future<bool> _criarEEnviarOferta() async {
    try {
      // Criar oferta SDP
      final offerOptions = <String, dynamic>{
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
        'voiceActivityDetection': true,
      };
      
      final offer = await _peerConnection!.createOffer(offerOptions);
      await _peerConnection!.setLocalDescription(offer);
      
      debugPrint('[AIA] Oferta SDP criada: ${offer.sdp}');

      // Enviar oferta para a OpenAI usando HttpClient para controle preciso dos cabeçalhos
      final client = HttpClient();
      final uri = Uri.parse("https://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17");
      final request = await client.postUrl(uri);
      
      // Configurar cabeçalhos exatamente como a API espera
      request.headers.set('Authorization', 'Bearer ${dotenv.env['OPENAI_API_KEY']}');
      request.headers.set('Content-Type', 'application/sdp');
      
      // Enviar o corpo da requisição
      request.write(offer.sdp);
      
      // Obter resposta
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      // Verificar se a resposta começa com "v=0", que é o início de um SDP válido
      if (responseBody.trim().startsWith('v=0')) {
        debugPrint('[AIA] Resposta SDP recebida com sucesso');
      } else {
        // Verificar se a resposta é um JSON de erro
        try {
          if (response.statusCode != 200) {
            debugPrint('[AIA] Erro HTTP: ${response.statusCode}');
            try {
              final errorJson = jsonDecode(responseBody);
              if (errorJson.containsKey('error')) {
                if (errorJson['error'] is Map) {
                  debugPrint('[AIA] Erro da API OpenAI: ${errorJson['error']['message']}');
                } else {
                  debugPrint('[AIA] Erro da API OpenAI: ${errorJson['error']}');
                }
              } else {
                debugPrint('[AIA] Erro ao obter SDP da OpenAI: $responseBody');
              }
            } catch (e) {
              // Se não for JSON, apenas exibir a resposta como está
              debugPrint('[AIA] Erro ao obter SDP da OpenAI: $responseBody');
            }
          } else {
            debugPrint('[AIA] Resposta inesperada da API: $responseBody');
          }
        } catch (e) {
          debugPrint('[AIA] Erro ao processar resposta: $e');
        }
        
        // Aguardar um pouco antes de tentar novamente
        await Future.delayed(Duration(seconds: 2));
        
        // Tentar novamente uma vez
        debugPrint('[AIA] Tentando reconectar após erro...');
        return await _tentarReconectar();
      }
      
      try {
        // Configurar resposta como descrição remota
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(responseBody, 'answer'),
        );
        debugPrint('[AIA] Descrição remota configurada com sucesso');
        return true;
      } catch (e) {
        debugPrint('[AIA] Erro ao configurar descrição remota: $e');
        return false;
      }
    } catch (e) {
      debugPrint('[AIA] Erro ao criar e enviar oferta: $e');
      return false;
    }
  }

  void _processarMensagem(String rawData) {
    try {
      debugPrint('[AIA] Mensagem recebida: $rawData');
      final data = jsonDecode(rawData);
      final type = data['type'];

      switch (type) {
        case 'session.created':
          debugPrint('[AIA] Sessão criada, ID: ${data['session']['id']}');
          _enviarConfiguracao();
          onListeningStarted?.call();
          break;
          
        case 'response.audio.delta':
          final bytes = base64Decode(data['delta']);
          debugPrint('[AIA] Áudio delta recebido: ${bytes.length} bytes');
          onAudioResponse?.call(Uint8List.fromList(bytes));
          break;
          
        case 'response.done':
          debugPrint('[AIA] Resposta concluída');
          onConversationDone?.call();
          break;
          
        case 'error':
          // Verificar se o erro tem uma mensagem
          if (data.containsKey('error') && data['error'] is Map && data['error'].containsKey('message')) {
            debugPrint('[AIA] Erro recebido: ${data['error']['message']}');
          } else if (data.containsKey('message')) {
            debugPrint('[AIA] Erro recebido: ${data['message']}');
          } else {
            debugPrint('[AIA] Erro recebido sem mensagem detalhada');
          }
          break;
          
        // Ignorando eventos relacionados a texto, já que só queremos áudio
        case 'response.text.delta':
          // Ignorando eventos de texto
          debugPrint('[AIA] Ignorando evento de texto');
          break;
          
        case 'response.text.start':
          // Ignorando eventos de texto
          debugPrint('[AIA] Ignorando evento de início de texto');
          break;
          
        case 'response.text.end':
          // Ignorando eventos de texto
          debugPrint('[AIA] Ignorando evento de fim de texto');
          break;
          
        default:
          debugPrint("[AIA] Evento desconhecido: $type");
      }
    } catch (e) {
      debugPrint("[AIA] Erro ao processar evento: $e");
    }
  }

  void _enviarConfiguracao() {
    if (_dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      final settings = {
        "type": "session.update",
        "session": {
          "modalities": ["audio", "text"],
          "voice": "alloy", 
          "output_audio_format": "pcm16",
          "input_audio_transcription": {"model": "whisper-1"},
          "turn_detection": {
            "type": "server_vad",
            "threshold": 0.7, 
            "silence_duration_ms": 1000, // 5 segundos de silêncio antes de considerar que o usuário terminou
            "prefix_padding_ms": 300
          },
          "temperature": 0.7,
          "max_response_output_tokens": "inf",
          "instructions": "Você é uma IA que se chama 'ÁIA' e inicialmente você pergunta o nome do usuário."
        }
      };
      
      final jsonString = jsonEncode(settings);
      debugPrint('[AIA] Enviando configuração: $jsonString');
      _dataChannel!.send(RTCDataChannelMessage(jsonString));
    } else {
      debugPrint("[AIA] Canal de dados não está pronto para enviar configuração. Estado: ${_dataChannel?.state}");
    }
  }

  Future<bool> _tentarReconectar() async {
    try {
      debugPrint('[AIA] Tentando reconectar...');
      
      // Criar nova oferta SDP
      final offerOptions = <String, dynamic>{
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
        'voiceActivityDetection': true,
      };
      
      final offer = await _peerConnection!.createOffer(offerOptions);
      await _peerConnection!.setLocalDescription(offer);
      
      debugPrint('[AIA] Nova oferta SDP criada para reconexão');

      // Enviar oferta para a OpenAI
      final client = HttpClient();
      final uri = Uri.parse("https://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17");
      final request = await client.postUrl(uri);
      
      request.headers.set('Authorization', 'Bearer ${dotenv.env['OPENAI_API_KEY']}');
      request.headers.set('Content-Type', 'application/sdp');
      
      request.write(offer.sdp);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (responseBody.trim().startsWith('v=0')) {
        debugPrint('[AIA] Reconexão bem-sucedida');
        
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(responseBody, 'answer'),
        );
        
        return true;
      } else {
        debugPrint('[AIA] Falha na reconexão: resposta inválida');
        return false;
      }
    } catch (e) {
      debugPrint('[AIA] Erro durante a reconexão: $e');
      return false;
    }
  }

  Future<void> encerrarConversa() async {
    debugPrint('[AIA] Encerrando conversa...');
    
    try {
      await AudioService.pararCapturaDeAudio();
      
      if (_dataChannel != null) {
        await _dataChannel!.close();
        _dataChannel = null;
      }
      
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) => track.stop());
        await _localStream!.dispose();
        _localStream = null;
      }
      
      if (_remoteStream != null) {
        _remoteStream!.getTracks().forEach((track) => track.stop());
        await _remoteStream!.dispose();
        _remoteStream = null;
      }
      
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      
      _isConnected = false;
      debugPrint('[AIA] Conversa encerrada com sucesso');
    } catch (e) {
      debugPrint('[AIA] Erro ao encerrar conversa: $e');
    }
  }
}
