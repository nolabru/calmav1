import 'package:calma_flutter/features/aia/aia_screen.dart';
import 'package:calma_flutter/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:calma_flutter/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:calma_flutter/features/home/presentation/home_screen.dart';
import 'package:calma_flutter/features/privacy/presentation/policy_screen.dart';
import 'package:calma_flutter/features/insights/insights_screen.dart';
import 'package:calma_flutter/features/terms/presentation/terms_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:calma_flutter/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:calma_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:calma_flutter/features/auth/presentation/screens/signup_screen.dart';
import 'package:calma_flutter/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:calma_flutter/core/di/injection.dart';
import 'package:calma_flutter/features/auth/presentation/viewmodels/auth_viewmodel.dart';

/// AppRouter - Configuração centralizada de rotas do aplicativo
///
/// Gerencia todas as rotas da aplicação utilizando go_router,
/// implementando uma navegação tipo pilha com transições personalizadas.
class AppRouter {
  // Obtém o AuthViewModel para verificar o estado de autenticação
  static final _authViewModel = getIt<AuthViewModel>();
  
  // Cria um notificador para forçar a reavaliação das rotas quando o estado de autenticação mudar
  static final _refreshListenable = _AuthRefreshNotifier(_authViewModel);
  
  /// Configuração principal do Go Router
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _refreshListenable,
    redirect: (context, state) {
      // Aguardar a inicialização do AuthViewModel
      if (!_authViewModel.isInitialized) {
        debugPrint("🧭 ROUTER: AuthViewModel ainda não inicializado, aguardando...");
        return null;
      }
      
      final isLoggedIn = _authViewModel.currentUser != null;
      final path = state.uri.path;
      
      debugPrint("🧭 ROUTER: Verificando redirecionamento para: $path");
      debugPrint("🧭 ROUTER: Usuário logado: $isLoggedIn");
      if (isLoggedIn && _authViewModel.currentUser != null) {
        debugPrint("🧭 ROUTER: ID do usuário: ${_authViewModel.currentUser!.id}");
        debugPrint("🧭 ROUTER: Email do usuário: ${_authViewModel.currentUser!.email}");
      }
      
      final isAuthRoute = path == '/login' || 
                          path == '/signup' || 
                          path == '/' ||
                          path == '/forgot-password' ||
                          path == '/terms' ||
                          path == '/privacy' ||
                          path == '/email-confirmation';
      
      // Se não estiver logado e não for uma rota de autenticação, redirecionar para login
      if (!isLoggedIn && !isAuthRoute && path != '/onboarding') {
        debugPrint("🧭 ROUTER: Redirecionando para /login (usuário não logado tentando acessar rota protegida)");
        return '/login';
      }
      
      // Se estiver logado e for uma rota de autenticação, redirecionar para home
      if (isLoggedIn && (path == '/login' || path == '/signup')) {
        debugPrint("🧭 ROUTER: Redirecionando para /home (usuário logado tentando acessar rota de autenticação)");
        return '/home';
      }
      
      debugPrint("🧭 ROUTER: Sem redirecionamento necessário para: $path");
      return null;
    },
    routes: [
      // Rota inicial - Welcome Screen
      GoRoute(
        path: '/',
        name: 'welcome',
        pageBuilder:
            (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: WelcomeScreen(
                onGetStarted: () => _navigateToOnboarding(context),
                onLogin: () => _navigateToLogin(context),
                onTerms: () => _navigateToTerms(context),
                onPrivacy: () => _navigateToPrivacy(context),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),

      // Rota de Login
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder:
            (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const LoginScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
      ),

      // Rota de Cadastro
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder:
            (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const SignUpScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
      ),

      // Rota de Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder:
            (context, state) {
              // Verificar se há um parâmetro de página inicial
              final pageParam = state.uri.queryParameters['page'];
              final initialPage = pageParam != null ? int.tryParse(pageParam) : null;
              
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: OnboardingScreen(initialPage: initialPage),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
      ),

      // Rotas adicionais serão implementadas conforme avançamos no desenvolvimento
      GoRoute(
        path: '/terms',
        name: 'terms',
        pageBuilder:
            (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const TermsScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),

      GoRoute(
        path: '/privacy',
        name: 'privacy',
        pageBuilder:
            (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const PolicyScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder:
            (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),

      GoRoute(
        path: '/insights',
        name: 'insights',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const InsightsScreen()),
      ),

      GoRoute(
        path: '/aia',
        name: 'aia',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const AiaScreen()),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
            ),
      ),
      
      // Rota de confirmação de email
      GoRoute(
        path: '/email-confirmation',
        name: 'email-confirmation',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: EmailConfirmationScreen(email: email),
          );
        },
      ),
    ],
  );

  /// Navega para a tela de onboarding/cadastro
  static void _navigateToOnboarding(BuildContext context) {
    // Após o cadastro, direcionar para o onboarding
    context.goNamed('onboarding');
  }

  /// Navega para a tela de login
  static void _navigateToLogin(BuildContext context) {
    context.goNamed('login');
  }

  /// Navega para a tela de termos de uso
  static void _navigateToTerms(BuildContext context) {
    // Será implementado quando criarmos a tela de termos
    debugPrint('Navegando para Termos...');
    context.pushNamed('terms');
  }

  /// Navega para a tela de política de privacidade
  static void _navigateToPrivacy(BuildContext context) {
    // Será implementado quando criarmos a tela de privacidade
    debugPrint('Navegando para Privacidade...');
    context.pushNamed('privacy');
  }
}

/// Notificador para forçar a reavaliação das rotas quando o estado de autenticação mudar
class _AuthRefreshNotifier extends ChangeNotifier {
  final AuthViewModel _authViewModel;
  
  _AuthRefreshNotifier(this._authViewModel) {
    // Ouvir mudanças no AuthViewModel
    _authViewModel.addListener(_handleAuthChange);
  }
  
  void _handleAuthChange() {
    // Notificar o GoRouter para reavaliar as rotas
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authViewModel.removeListener(_handleAuthChange);
    super.dispose();
  }
}
