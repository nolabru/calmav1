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
  String _statusMessage = "Iniciando...";
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
    setState(() {
      _statusMessage = "Verificando permissões...";
    });
    
    final permissoesOk = await AudioService.solicitarPermissaoMicrofone();
    if (!permissoesOk) {
      _mostrarErro('Permissão de microfone negada.');
      return;
    }

    setState(() {
      _statusMessage = "Conectando à OpenAI...";
    });

    _openAIService = OpenAIRealtimeService(
      onAudioResponse: (audioData) {
        debugPrint('[AIA] 🎧 Áudio reproduzido (${audioData.length} bytes)');
        setState(() {
          _statusMessage = "Ouvindo resposta da IA...";
        });
      },
      onConversationDone: () {
        setState(() {
          _isListening = false;
          _statusMessage = "Conversa finalizada";
        });
      },
    );

    final conectado = await _openAIService!.iniciarConexaoComOpenAI();
    if (!conectado) {
      _mostrarErro('Falha ao conectar com a API da OpenAI. Verifique sua conexão com a internet e tente novamente.');
      return;
    }

    setState(() {
      _isConnecting = false;
      _isListening = true;
      _statusMessage = "AIA está ouvindo...";
    });
  }

  void _encerrarConversa() {
    _openAIService?.encerrarConversa();
    _openAIService = null;
    if (mounted) {
      setState(() {
        _isListening = false;
        _statusMessage = "Conversa encerrada";
      });
    }
  }

  void _mostrarErro(String mensagem) {
    debugPrint('[AIA] Erro: $mensagem');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: () {
            _iniciarConexao();
          },
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _isListening = false;
        _isConnecting = false;
        _statusMessage = "Erro de conexão";
      });
    }
  }

  void _alternarEscuta() {
    if (_isListening) {
      setState(() {
        _statusMessage = "Encerrando conversa...";
      });
      _encerrarConversa();
    } else {
      setState(() {
        _isConnecting = true;
        _statusMessage = "Iniciando conexão...";
      });
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
          'AIA - Assistente de Voz',
          style: TextStyle(color: Color(0xFF333333), fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          // Botão para reconectar
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isConnecting ? null : _iniciarConexao,
            tooltip: 'Reconectar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting)
                        const CircularProgressIndicator(color: Color(0xFF9D82FF)),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_isListening && !_isConnecting)
                        const Text(
                          'Fale algo para conversar com a IA...',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
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
