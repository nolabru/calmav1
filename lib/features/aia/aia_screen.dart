import 'package:flutter/material.dart';
import 'package:calma_flutter/features/aia/services/audio_service.dart';
import 'package:calma_flutter/features/aia/services/openai_realtime_service.dart';

class AiaScreen extends StatefulWidget {
  const AiaScreen({super.key});

  @override
  State<AiaScreen> createState() => _AiaScreenState();
}

class _AiaScreenState extends State<AiaScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isConnecting = true;
  bool _isListening = false;
  String _statusMessage = "Iniciando...";
  OpenAIRealtimeService? _openAIService;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    _iniciarConexao();
  }

  @override
  void dispose() {
    _encerrarConversa();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _iniciarConexao() async {
    setState(() {
      _statusMessage = "Verificando permissões...";
    });
    
    // Verificar permissão do microfone
    final permissaoOk = await AudioService.solicitarPermissaoMicrofone();
    if (!permissaoOk) {
      _mostrarErro('Permissão de microfone negada. O aplicativo precisa de acesso ao microfone para funcionar.');
      return;
    }
    
    setState(() {
      _statusMessage = "Conectando à OpenAI...";
    });

    // Criar serviço com callbacks
    _openAIService = OpenAIRealtimeService(
      onAudioResponse: (audioData) {
        debugPrint('[AIA Screen] Recebendo áudio: ${audioData.length} bytes');
        setState(() {
          _statusMessage = "Ouvindo resposta da IA...";
        });
        
        // Pausar a animação enquanto a IA está falando
        if (_animationController.isAnimating) {
          _animationController.stop();
        }
      },
      onConversationDone: () {
        debugPrint('[AIA Screen] Conversa finalizada');
        setState(() {
          _isListening = false;
          _statusMessage = "Conversa finalizada";
        });
        
        // Parar a animação quando a conversa terminar
        if (_animationController.isAnimating) {
          _animationController.stop();
        }
      },
      onListeningStarted: () {
        debugPrint('[AIA Screen] Começando a ouvir');
        setState(() {
          _statusMessage = "AIA está ouvindo...";
        });
        
        // Iniciar a animação quando começar a ouvir
        if (!_animationController.isAnimating) {
          _animationController.repeat(reverse: true);
        }
      },
    );

    // Iniciar conexão WebRTC
    try {
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
    } catch (e) {
      _mostrarErro('Erro ao iniciar conexão: $e');
    }
  }

  Future<void> _encerrarConversa() async {
    if (mounted) {
      setState(() {
        _isListening = false;
        _statusMessage = "Encerrando conversa...";
      });
    }

    // Parar a animação
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    // Encerrar a conversa de forma assíncrona
    try {
      if (_openAIService != null) {
        await _openAIService!.encerrarConversa();
        _openAIService = null;
      }
      
      if (mounted) {
        setState(() {
          _statusMessage = "Conversa encerrada";
        });
      }
    } catch (e) {
      debugPrint('[AIA Screen] Erro ao encerrar conversa: $e');
      if (mounted) {
        setState(() {
          _statusMessage = "Erro ao encerrar conversa";
        });
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: _iniciarConexao,
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

  Future<void> _alternarEscuta() async {
    // Evitar múltiplos cliques enquanto está processando
    if (_isConnecting) return;
    
    if (_isListening) {
      // Se estiver ouvindo, encerrar a conversa
      await _encerrarConversa();
    } else {
      // Se não estiver ouvindo, iniciar uma nova conexão
      setState(() {
        _isConnecting = true;
        _statusMessage = "Iniciando conexão...";
      });
      
      // Pequeno atraso para garantir que a UI seja atualizada antes de iniciar a conexão
      await Future.delayed(const Duration(milliseconds: 100));
      await _iniciarConexao();
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
                      _buildStatusIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_isListening && !_isConnecting)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Fale algo para conversar com a IA...',
                            style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                            textAlign: TextAlign.center,
                          ),
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

  Widget _buildStatusIndicator() {
    if (_isConnecting) {
      return const CircularProgressIndicator(color: Color(0xFF9D82FF));
    } else if (_isListening) {
      return _buildPulsingCircle();
    } else {
      return const Icon(Icons.mic_off, color: Colors.grey, size: 40);
    }
  }

  Widget _buildPulsingCircle() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: const Color(0xFF9D82FF), width: 2),
          ),
          child: Center(
            child: Container(
              width: 30 * _animation.value,
              height: 30 * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9D82FF).withOpacity(0.5),
              ),
            ),
          ),
        );
      },
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
