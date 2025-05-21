import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:calma_flutter/features/onboarding/presentation/components/onboarding_content_model.dart';
// Importe a classe revisada
import 'package:calma_flutter/features/onboarding/presentation/components/onboarding_screen_builder.dart';
import 'package:calma_flutter/core/di/injection.dart';
import 'package:calma_flutter/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:calma_flutter/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:calma_flutter/features/reminders/presentation/viewmodels/reminder_viewmodel.dart';

class OnboardingScreen extends StatefulWidget {
  /// Página inicial do onboarding (opcional)
  final int? initialPage;
  
  const OnboardingScreen({super.key, this.initialPage});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ValueNotifier<bool> _isNextEnabled = ValueNotifier<bool>(true);
  final _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 12;
  
  // Controladores para os campos do formulário da página 11
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Estado para o erro de email
  String? _emailError;
  
  // Estado para o checkbox "Lembre-se de mim"
  bool _rememberMe = false;
  
  // ViewModels
  late final AuthViewModel _authViewModel;
  late final ReminderViewModel _reminderViewModel;
  
  @override
  void initState() {
    super.initState();
    _authViewModel = getIt<AuthViewModel>();
    _reminderViewModel = getIt<ReminderViewModel>();
    
    // Se houver uma página inicial definida, configurar para ir para ela
    if (widget.initialPage != null) {
      debugPrint('🔄 ONBOARDING: Página inicial definida: ${widget.initialPage}');
      
      // Inicializar o PageController com a página inicial
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('🔄 ONBOARDING: Navegando para a página ${widget.initialPage}');
        
        // Definir a página atual no estado
        setState(() {
          _currentPage = widget.initialPage!;
        });
        
        // Navegar para a página especificada
        _pageController.jumpToPage(widget.initialPage!);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    FocusScope.of(context).unfocus();
    
    // Verificar se estamos na página 11 (índice 10)
    if (_currentPage == 10) {
      // Na página 11, tentamos cadastrar o usuário antes de avançar
      _registerUser();
    } else if (_currentPage == 11) {
      // Na página 12 (índice 11), salvamos os lembretes antes de avançar
      _saveReminders();
    } else if (_currentPage < _totalPages - 1) {
      // Para outras páginas, apenas avançamos
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Na última página, completamos o onboarding
      _completeOnboarding();
    }
  }
  
  // Método para salvar os lembretes no Supabase
  void _saveReminders() async {
    // Mostrar indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Salvar os lembretes no Supabase
    final success = await _reminderViewModel.saveReminders();
    
    // Fechar o indicador de carregamento
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    if (success && mounted) {
      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lembretes salvos com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navegar para a tela principal (home) em vez de avançar para a próxima página
      debugPrint('🔄 ONBOARDING: Navegando para a tela principal após salvar lembretes');
      _completeOnboarding(); // Usar o método existente para navegar para a tela home
    } else if (mounted) {
      // Mostrar mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_reminderViewModel.errorMessage ?? 'Erro ao salvar lembretes'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Método para registrar o usuário no Supabase
  void _registerUser() async {
    // Limpar erro de email anterior
    setState(() {
      _emailError = null;
    });
    
    // Capturar os dados do formulário
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    
    // Mostrar indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Criar conta no Supabase
    final success = await _authViewModel.signUp(
      email,
      password,
      name,
      rememberMe: _rememberMe, // Passar a preferência "Lembre-se de mim"
    );
    
    // Fechar o indicador de carregamento
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    if (success && mounted) {
      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navegar para a tela de confirmação de email usando GoRouter
      context.pushNamed(
        'email-confirmation',
        queryParameters: {'email': email},
      );
    } else if (mounted) {
      // Verificar se o erro é de email já cadastrado
      final errorMessage = _authViewModel.errorMessage ?? 'Erro ao criar conta';
      final isEmailAlreadyRegistered = errorMessage.contains('Email já cadastrado');
      
      // Se o email já estiver cadastrado, definir o erro de email
      if (isEmailAlreadyRegistered) {
        setState(() {
          _emailError = 'Email já cadastrado';
        });
        
        // Focar no campo de email para facilitar a correção
        FocusScope.of(context).requestFocus(FocusNode());
        Future.delayed(Duration(milliseconds: 300), () {
          _emailController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _emailController.text.length,
          );
          FocusScope.of(context).requestFocus(FocusNode());
        });
      } else {
        // Para outros erros, mostrar um SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    context.goNamed('welcome');
  }

  void _completeOnboarding() async {
    // Quando o usuário terminar o onboarding, navegar para a tela inicial
    context.goNamed('home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6E1FA), Color(0xFFEAE3FB)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Borda decorativa
              _buildBorder(),

              // Conteúdo principal
              Column(
                children: [
                  // Barra superior com botão de voltar
                  _buildTopBar(),

                  // Conteúdo das páginas (sem barra de progresso e botão)
                  // Dentro do método build() da classe _OnboardingScreenState
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: onboardingData.length,
                      physics:
                          const NeverScrollableScrollPhysics(), // Impedir deslize manual
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });

                        // Definir estado inicial do botão com base no tipo de conteúdo
                        final contentType = onboardingData[index].type;
                        final needsValidation =
                            contentType == OnboardingContentType.textInput ||
                            contentType == OnboardingContentType.optionSelect;

                        // Páginas informativas não precisam de validação
                        _isNextEnabled.value = !needsValidation;
                      },
                      itemBuilder: (context, index) {
                        final pageData = onboardingData[index];
                        
                        // Verificar se é a página 11 (índice 10) para passar os controladores
                        if (index == 10) { // Página de informações de contato
                          return OnboardingScreenBuilder.buildScreenContent(
                            content: pageData,
                            onValidationChanged: (isValid) {
                              _isNextEnabled.value = isValid;
                            },
                            nameController: _nameController,
                            emailController: _emailController,
                            phoneController: _phoneController,
                            passwordController: _passwordController,
                            confirmPasswordController: _confirmPasswordController,
                            emailError: _emailError,
                            rememberMe: _rememberMe,
                            onRememberMeChanged: (value) {
                              setState(() {
                                _rememberMe = value;
                              });
                            },
                          );
                        } else {
                          return OnboardingScreenBuilder.buildScreenContent(
                            content: pageData,
                            onValidationChanged: (isValid) {
                              _isNextEnabled.value = isValid;
                            },
                          );
                        }
                      },
                    ),
                  ),
                  // Barra de progresso FIXA
                  _buildProgressIndicator(),

                  // Botão de próximo FIXO
                  _buildNextButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Progresso fixo na parte inferior
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "${_currentPage + 1}/$_totalPages",
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isNextEnabled,
      builder: (context, isEnabled, _) {
        return Container(
          margin: const EdgeInsets.only(
            bottom: 20.0,
            top: 16.0,
            left: 20,
            right: 20,
          ),
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? _handleNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C89B8),
              foregroundColor: Colors.white,
              elevation: 0,
              // Adiciona cor de desabilitado
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              _currentPage == _totalPages - 1 ? "Concluir" : "Próximo",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBorder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton.icon(
              onPressed:
                  () => _currentPage > 0 ? _handleBack() : _skipOnboarding(),
              icon: const Icon(
                Icons.arrow_back,
                size: 18,
                color: Colors.black87,
              ),
              label: const Text(
                'Voltar',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
