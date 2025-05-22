// ===============================
// FILE: aia_screen.dart
// ===============================
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:calma_flutter/features/aia/services/audio_service.dart';
import 'package:calma_flutter/features/aia/services/openai_realtime_service.dart';

class AiaScreen extends StatefulWidget {
  const AiaScreen({super.key});

  @override
  State<AiaScreen> createState() => _AiaScreenState();
}

class _AiaScreenState extends State<AiaScreen> {
  bool _isConnecting = true;
  bool _isListening = false;
  String _aiResponse = '';
  OpenAIRealtimeService? _openAIService;

  @override
  void initState() {
    super.initState();
    _iniciarConexao();
  }

  @override
  void dispose() {
    _encerrarConversa();
    super.dispose();
  }

  Future<void> _iniciarConexao() async {
    try {
      final permissoesOk = await AudioService.solicitarPermissaoMicrofone();
      if (!permissoesOk) {
        _mostrarErro('Permissão de microfone negada.');
        return;
      }

      _openAIService = OpenAIRealtimeService(
        onTextResponse: (text) {
          setState(() {
            _aiResponse += text;
          });
        },
        onAudioResponse: (audioBytes) {
          debugPrint('[AIA] Áudio recebido (${audioBytes.length} bytes)');
        },
        onConversationDone: () {
          setState(() => _isListening = false);
        },
      );

      final conectado = await _openAIService!.iniciarConexaoComOpenAI();
      if (!conectado) {
        _mostrarErro('Falha ao conectar com a API da OpenAI.');
        return;
      }

      setState(() {
        _isConnecting = false;
        _isListening = true;
      });
    } catch (e) {
      _mostrarErro('Erro ao iniciar conexão com a AIA: $e');
    }
  }

  void _encerrarConversa() {
    _openAIService?.encerrarConversa();
    _openAIService = null;
    setState(() => _isListening = false);
  }

  void _mostrarErro(String mensagem) {
    debugPrint('[AIA] Erro: $mensagem');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
    setState(() => _isConnecting = false);
  }

  void _alternarEscuta() {
    if (_isListening) {
      _encerrarConversa();
    } else {
      _iniciarConexao();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () {
            _encerrarConversa();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'AIA',
          style: TextStyle(color: Color(0xFF333333), fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: _isConnecting
                      ? const _ConectandoWidget()
                      : _RespostaWidget(texto: _aiResponse),
                ),
              ),
            ),
            _BotaoMicrofone(ativo: _isListening, onPressed: _alternarEscuta),
          ],
        ),
      ),
    );
  }
}

// ============================
// Widgets auxiliares
// ============================

class _ConectandoWidget extends StatelessWidget {
  const _ConectandoWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/1813edc8-2cfd-4f21-928d-16663b4fe844.png', width: 180),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Color(0xFF9D82FF)),
        const SizedBox(height: 16),
        const Text('Conectando com a AIA...', style: TextStyle(fontSize: 16, color: Color(0xFF9D82FF))),
      ],
    );
  }
}

class _RespostaWidget extends StatelessWidget {
  final String texto;

  const _RespostaWidget({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        texto.isEmpty ? 'Estou ouvindo...' : texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontStyle: texto.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}

class _BotaoMicrofone extends StatelessWidget {
  final bool ativo;
  final VoidCallback onPressed;

  const _BotaoMicrofone({required this.ativo, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFF9D82FF) : Colors.grey[200],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            ativo ? Icons.mic : Icons.mic_none,
            color: ativo ? Colors.white : Colors.black38,
            size: 32,
          ),
        ),
      ),
    );
  }
}
