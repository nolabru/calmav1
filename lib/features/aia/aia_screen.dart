import 'package:flutter/material.dart';
import 'dart:math';
import 'package:calma_flutter/features/aia/services/audio_service.dart';
import 'package:calma_flutter/features/aia/services/openai_realtime_service.dart';

class AiaScreen extends StatefulWidget {
  const AiaScreen({super.key});

  @override
  State<AiaScreen> createState() => _AiaScreenState();
}

class _AiaScreenState extends State<AiaScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  // Imagem para usar na animação
  final String _imageAsset = 'assets/images/ba4aa252-6ce8-4eed-a0e1-9b5265138a7a.png';
  bool _isConnecting = true;
  bool _isListening = false;
  bool _isMuted = false; // Variável para controlar se o áudio está mudo
  String _statusMessage = "Iniciando...";
  OpenAIRealtimeService? _openAIService;

  @override
  void initState() {
    super.initState();

    // Controlador para a animação de movimento vertical
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Animação de deslizamento suave para cima e para baixo
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),  // Começa um pouco abaixo
      end: const Offset(0, -0.03),   // Termina um pouco acima
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Iniciar a animação com repetição contínua
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
      _statusMessage = "Respire... Você chegou.";
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
        debugPrint('[AIA Screen] Resposta recebida');
        // Reiniciar a conexão automaticamente para manter a conversa contínua
        if (_openAIService != null && !_openAIService!.isConnected) {
          _iniciarConexao();
        } else {
          setState(() {
            _statusMessage = "Estou ouvindo...";
          });
          
          // Reiniciar a animação para indicar que está ouvindo novamente
          if (!_animationController.isAnimating) {
            _animationController.repeat(reverse: true);
          }
        }
      },
      onListeningStarted: () {
        debugPrint('[AIA Screen] Começando a ouvir');
        setState(() {
          _statusMessage = "Estou ouvindo...";
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
        _statusMessage = "Estou ouvindo...";
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
  
  // Método para alternar entre mudo e não mudo
  void _alternarMudo() {
    setState(() {
      _isMuted = !_isMuted;
      
      if (_isMuted) {
        // Implementar lógica para mutar o áudio
        AudioService.muteAudio();
        _statusMessage = "Áudio mutado";
      } else {
        // Implementar lógica para desmutar o áudio
        AudioService.unmuteAudio();
        _statusMessage = "Estou ouvindo...";
      }
    });
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
                      const SizedBox(height: 20),
                      // Botão de mudo
                      if (_isListening && !_isConnecting)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: _isMuted ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            onPressed: _alternarMudo,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF9333EA), fontWeight: FontWeight.w400),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (_isListening && !_isConnecting)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Fale algo para conversar com a AIA...',
                            style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
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
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: 400, 
            height: 400, 
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                _imageAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Classe _BotaoMicrofone removida para manter a conversa contínua
