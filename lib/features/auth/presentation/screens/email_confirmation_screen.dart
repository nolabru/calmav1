import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:calma_flutter/core/constants/app_colors.dart';
import 'package:calma_flutter/core/constants/app_text_styles.dart';
import 'package:calma_flutter/presentation/common_widgets/primary_button.dart';
import 'package:calma_flutter/core/di/injection.dart';
import 'package:calma_flutter/features/auth/presentation/viewmodels/auth_viewmodel.dart';

/// EmailConfirmationScreen - Tela de confirmação de email
///
/// Exibida após o cadastro, informando ao usuário que um email foi enviado
/// e fornecendo um botão para confirmar quando o email for verificado.
class EmailConfirmationScreen extends StatefulWidget {
  /// Email do usuário
  final String email;

  /// Construtor da EmailConfirmationScreen
  const EmailConfirmationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  late final AuthViewModel _authViewModel;
  bool _isLoading = false;
  bool _isVerified = false;
  Timer? _verificationTimer;
  
  @override
  void initState() {
    super.initState();
    _authViewModel = getIt<AuthViewModel>();
    _checkEmailVerification();
    
    // Configurar um timer para verificar periodicamente se o email foi confirmado
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isVerified && mounted) {
        _checkEmailVerification();
      } else if (_isVerified) {
        // Se o email for verificado, cancelar o timer
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }
  
  /// Verifica se o email foi confirmado
  Future<void> _checkEmailVerification() async {
    if (_isLoading) return; // Evitar verificações simultâneas
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Recarregar o usuário para obter as informações mais recentes
      await _authViewModel.reloadCurrentUser();
      
      final isVerified = await _authViewModel.isEmailVerified();
      
      if (mounted) {
        setState(() {
          _isVerified = isVerified;
          _isLoading = false;
        });
        
        // Se o email foi verificado, mostrar uma mensagem de sucesso
        if (isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verificado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Envia um novo email de verificação
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authViewModel.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de verificação reenviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reenviar email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Continua para a próxima tela sem verificar o email
  /// 
  /// NOTA: Esta é uma modificação temporária para desenvolvimento.
  /// A verificação de email foi desativada para permitir testes em dispositivos
  /// diferentes sem a necessidade de clicar no link de verificação.
  void _continueToNextScreen() async {
    debugPrint('🔄 EMAIL_CONFIRMATION: Continuando para a próxima tela (modo de desenvolvimento)');
    
    // Mostrar indicador de carregamento
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Navegar diretamente para a página 12 do onboarding (lembretes)
      // sem verificar se o email foi confirmado
      debugPrint('🔄 EMAIL_CONFIRMATION: Navegando para a tela de onboarding (página 12)');
      
      // Usar pushReplacementNamed em vez de goNamed para garantir que a tela atual seja substituída
      context.pushReplacementNamed('onboarding', queryParameters: {'page': '11'});
      
      // Mostrar mensagem de boas-vindas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure seus lembretes.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('🔄 EMAIL_CONFIRMATION: Erro ao navegar: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Mostrar mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao navegar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.calmaBlueLight, Color(0xFFD6BCFA)],
            stops: [0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Borda decorativa
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
              ),

              // Conteúdo principal
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Botão de voltar
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Ícone de email
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 60,
                        color: AppColors.calmaBlue,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Título
                    Text(
                      "Verifique seu email",
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.gray700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtítulo com o email
                    Text(
                      "Enviamos um link de confirmação para:",
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Email do usuário
                    Text(
                      widget.email,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.calmaBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Instruções
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Por favor, verifique sua caixa de entrada e clique no link de confirmação que enviamos.",
                            style: TextStyle(
                              color: AppColors.gray700,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Não se esqueça de verificar também sua pasta de spam.",
                            style: TextStyle(
                              color: AppColors.gray600,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botão para confirmar
                    PrimaryButton(
                      text: _isVerified 
                          ? "Continuar" 
                          : "Já verifiquei meu e-mail",
                      onPressed: _continueToNextScreen,
                      isLoading: _isLoading,
                      height: 52,
                      borderRadius: 50,
                    ),
                    const SizedBox(height: 16),

                    // Botão para reenviar email
                    if (!_isVerified)
                      TextButton(
                        onPressed: _isLoading ? null : _resendVerificationEmail,
                        child: Text(
                          "Reenviar email de confirmação",
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.calmaBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    
                    // Status de verificação
                    if (_isVerified)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Email verificado com sucesso!",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
