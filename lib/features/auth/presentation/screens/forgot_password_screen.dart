import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:calma_flutter/core/constants/app_colors.dart';
import 'package:calma_flutter/core/constants/app_text_styles.dart';
import 'package:calma_flutter/core/utils/mixin_utils.dart';
import 'package:calma_flutter/presentation/common_widgets/input_field.dart';
import 'package:calma_flutter/presentation/common_widgets/primary_button.dart';
import 'package:calma_flutter/presentation/common_widgets/text_button_custom.dart';
import 'package:calma_flutter/core/di/injection.dart';
import '../viewmodels/auth_viewmodel.dart';

enum ResetStep { emailEntry, codeVerification, newPassword }

/// ForgotPasswordScreen - Tela de recuperação de senha do aplicativo C'Alma
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with MixinsUtils {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // Controladores para código de verificação (6 dígitos)
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  // Controladores para nova senha
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthViewModel _authViewModel;
  String? _emailError;
  String? _passwordError;
  
  @override
  void initState() {
    super.initState();
    _authViewModel = getIt<AuthViewModel>();
  }

  // Etapa atual do fluxo

  ResetStep _currentStep = ResetStep.emailEntry;

  // Visibilidade da senha
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Gerencia o envio do e-mail para recuperação
  void _handleSendEmail() async {
    if (!_validateEmailForm()) return;

    final success = await _authViewModel.resetPassword(_emailController.text);
    
    if (success) {
      setState(() {
        _currentStep = ResetStep.codeVerification;
      });
    } else {
      // Identificar o tipo de erro e atualizar os campos correspondentes
      final errorMessage = _authViewModel.errorMessage ?? 'Erro ao enviar email de recuperação';
      
      if (errorMessage.contains('Email não cadastrado')) {
        setState(() {
          _emailError = 'Email não cadastrado';
        });
      } else if (errorMessage.contains('Email inválido')) {
        setState(() {
          _emailError = 'Email inválido';
        });
      } else {
        // Exibir erro geral em um dialog
        _showErrorDialog(errorMessage);
      }
    }
  }
  
  /// Exibe um dialog de erro com a mensagem fornecida
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Erro de Recuperação',
          style: AppTextStyles.heading4,
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.calmaBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gerencia a definição da nova senha
  void _handleSetNewPassword() async {
    if (!_validatePasswordForm()) return;

    // Aqui você precisaria implementar a lógica para definir a nova senha
    // usando o código de verificação e a nova senha
    // Como o AuthViewModel atual não tem um método específico para isso,
    // vamos simular por enquanto
    
    setState(() {
      _authViewModel.isLoading = true;
    });
    
    // Simulação de redefinição de senha
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _authViewModel.isLoading = false;
    });

    // Exibir mensagem de sucesso e voltar para login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Senha alterada com sucesso!"),
        backgroundColor: Colors.green,
      ),
    );

    _navigateToLogin();
  }

  bool _validateEmailForm() {
    final emailValid = validateEmail(_emailController.text);

    setState(() {
      _emailError = emailValid;
    });

    return emailValid == null;
  }

  /// Valida o formulário de nova senha
  bool _validatePasswordForm() {
    bool isValid = true;

    // Usando o método combine para validar múltiplas regras
    final passwordValid = combine([
      () => isEmpty(_newPasswordController.text, 'Por favor, insira uma senha'),
      () => moreThanSeven(_newPasswordController.text),
      () => hasNumber(_newPasswordController.text),
      () => upperLetter(_newPasswordController.text),
      () => lowerLetter(_newPasswordController.text),
    ]);

    // Verifica se a senha é válida
    if (passwordValid != null) {
      setState(() {
        _passwordError = passwordValid;
      });
      isValid = false;
    }
    // Verifica se as senhas coincidem
    else if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = "As senhas não coincidem";
      });
      isValid = false;
    }
    // Tudo ok
    else {
      setState(() {
        _passwordError = null;
      });
    }

    return isValid;
  }

  /// Método para validar o código de verificação
  bool _validateCode() {
    // Verifica se todos os campos estão preenchidos
    bool isComplete = _codeControllers.every(
      (controller) => controller.text.isNotEmpty,
    );

    if (!isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, preencha o código de verificação"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Opcional: Validar se o código tem 6 dígitos
    String fullCode =
        _codeControllers.map((controller) => controller.text).join();
    final codeValid = moreThanFive(fullCode);

    if (codeValid != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(codeValid), backgroundColor: Colors.red),
      );
      return false;
    }

    return true;
  }

  /// Gerencia a verificação do código
  void _handleVerifyCode() async {
    if (!_validateCode()) return;

    setState(() {
      _authViewModel.isLoading = true;
    });

    // Simulação de verificação do código
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _authViewModel.isLoading = false;
      _currentStep = ResetStep.newPassword;
    });
  }

  /// Navega para a tela de login
  void _navigateToLogin() {
    context.go('/login');
  }

  /// Volta para a etapa anterior
  void _goBack() {
    if (_currentStep == ResetStep.codeVerification) {
      setState(() {
        _currentStep = ResetStep.emailEntry;
      });
    } else if (_currentStep == ResetStep.newPassword) {
      setState(() {
        _currentStep = ResetStep.codeVerification;
      });
    } else {
      _navigateToLogin();
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
              _buildBorder(),

              // Conteúdo baseado na etapa atual
              _buildCurrentStep(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o conteúdo baseado na etapa atual
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case ResetStep.emailEntry:
        return _buildEmailEntryContent();
      case ResetStep.codeVerification:
        return _buildCodeVerificationContent();
      case ResetStep.newPassword:
        return _buildNewPasswordContent();
    }
  }

  /// Constrói a borda decorativa da tela
  Widget _buildBorder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
    );
  }

  /// Constrói o conteúdo da tela de entrada de email
  Widget _buildEmailEntryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão de voltar
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
            onPressed: _navigateToLogin,
          ),
          const SizedBox(height: 20),

          // Título da tela
          Text(
            "Esqueceu\nsua senha?",
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.gray700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(
            "Informe seu e-mail e enviaremos um código de verificação",
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 40),

          // Formulário de recuperação
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo de email
                InputField(
                  controller: _emailController,
                  label: "Email",
                  hint: "seuemail@exemplo.com",
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                ),
                const SizedBox(height: 30),

                // Botão de enviar
                PrimaryButton(
                  text: "Enviar código",
                  onPressed: _handleSendEmail,
                  isLoading: _authViewModel.isLoading,
                  height: 52,
                  borderRadius: 50,
                ),

                const SizedBox(height: 40),

                // Link para voltar ao login
                Center(
                  child: TextButtonCustom(
                    text: "Voltar para o login",
                    onPressed: _navigateToLogin,
                    textColor: AppColors.gray700,
                    textStyle: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a tela de verificação de código
  Widget _buildCodeVerificationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão de voltar
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
            onPressed: _goBack,
          ),
          const SizedBox(height: 20),

          // Título da tela
          Text(
            "Verificação",
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.gray700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo com email informado
          Text(
            "Digite o código de 6 dígitos que enviamos para ${_emailController.text}",
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 40),

          // Caixas do código de verificação (6 dígitos)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 45,
                height: 56,
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _codeFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  onChanged: (value) {
                    // Avança para o próximo campo se preenchido, volta se apagado
                    if (value.isNotEmpty && index < 5) {
                      _codeFocusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _codeFocusNodes[index - 1].requestFocus();
                    }
                  },
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: "",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),

          // Botão de verificar
          PrimaryButton(
            text: "Verificar",
            onPressed: _handleVerifyCode,
            isLoading: _authViewModel.isLoading,
            height: 52,
            borderRadius: 50,
          ),

          const SizedBox(height: 24),

          // Não recebeu o código?
          Center(
            child: Column(
              children: [
                Text(
                  "Não recebeu o código?",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
                TextButton(
                  onPressed: _authViewModel.isLoading ? null : _handleSendEmail,
                  child: Text(
                    "Reenviar",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.calmaBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a tela de definição de nova senha
  Widget _buildNewPasswordContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão de voltar
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
            onPressed: _goBack,
          ),
          const SizedBox(height: 20),

          // Título da tela
          Text(
            "Nova senha",
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.gray700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(
            "Crie uma nova senha para sua conta",
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 40),

          // Formulário de nova senha
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nova senha
                InputField(
                  controller: _newPasswordController,
                  label: "Nova senha",
                  hint: "Digite sua nova senha",
                  obscureText: _obscurePassword,
                  errorText: _passwordError,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Confirmar senha
                InputField(
                  controller: _confirmPasswordController,
                  label: "Confirmar senha",
                  hint: "Digite novamente a senha",
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // Botão de confirmar
                PrimaryButton(
                  text: "Confirmar nova senha",
                  onPressed: _handleSetNewPassword,
                  isLoading: _authViewModel.isLoading,
                  height: 52,
                  borderRadius: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
