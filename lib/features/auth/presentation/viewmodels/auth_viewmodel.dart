import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';

/// AuthViewModel - ViewModel para gerenciar o estado de autenticação
///
/// Gerencia o estado de autenticação e fornece métodos para interagir com o repositório.
class AuthViewModel extends ChangeNotifier {
  /// Repositório de autenticação
  final AuthRepository _repository;
  
  /// Indica se uma operação está em andamento
  bool isLoading = false;
  
  /// Mensagem de erro, se houver
  String? errorMessage;
  
  /// Usuário atualmente autenticado
  UserModel? currentUser;
  
  /// Indica se o ViewModel foi inicializado
  bool isInitialized = false;
  
  /// Subscription para o stream de usuários
  late StreamSubscription<UserModel?> _userSubscription;
  
  /// Construtor do AuthViewModel
  AuthViewModel(this._repository) {
    _initialize();
  }
  
  /// Inicializa o ViewModel
  Future<void> _initialize() async {
    debugPrint('🔄 VIEWMODEL: Inicializando AuthViewModel');
    
    // Ouvir mudanças no usuário
    _userSubscription = _repository.userChanges.listen((user) {
      debugPrint('🔄 VIEWMODEL: Mudança no usuário: ${user?.id}');
      currentUser = user;
      isInitialized = true;
      notifyListeners();
    });
    
    // Carregar o usuário atual
    await _loadCurrentUser();
  }
  
  /// Carrega o usuário atual, se houver
  Future<void> _loadCurrentUser() async {
    debugPrint('🔄 VIEWMODEL: Carregando usuário atual...');
    try {
      currentUser = await _repository.getCurrentUser();
      if (currentUser != null) {
        debugPrint('✅ VIEWMODEL: Usuário carregado com sucesso: ${currentUser!.id}');
      } else {
        debugPrint('⚠️ VIEWMODEL: Nenhum usuário atual encontrado');
      }
    } catch (e) {
      debugPrint('❌ VIEWMODEL: Erro ao carregar usuário atual: $e');
    }
    isInitialized = true;
    notifyListeners();
  }
  
  /// Recarrega o usuário atual
  Future<void> reloadCurrentUser() async {
    debugPrint('🔄 VIEWMODEL: Recarregando usuário atual...');
    await _loadCurrentUser();
  }
  
  /// Registra um novo usuário
  ///
  /// Retorna true se o cadastro for bem-sucedido
  /// 
  /// Se [rememberMe] for true, o usuário permanecerá logado mesmo após fechar o aplicativo
  Future<bool> signUp(String email, String password, String name, {bool rememberMe = false}) async {
    debugPrint('🔄 VIEWMODEL: Iniciando cadastro para: $email (rememberMe: $rememberMe)');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final result = await _repository.signUp(email, password, name, rememberMe: rememberMe);
    
    return result.fold(
      (error) {
        debugPrint('❌ VIEWMODEL: Erro no cadastro: $error');
        errorMessage = error;
        isLoading = false;
        notifyListeners();
        return false;
      },
      (user) {
        debugPrint('✅ VIEWMODEL: Cadastro bem-sucedido para: ${user.email}');
        currentUser = user;
        isLoading = false;
        notifyListeners();
        return true;
      }
    );
  }
  
  /// Autentica um usuário existente
  ///
  /// Retorna true se o login for bem-sucedido
  /// 
  /// Se [rememberMe] for true, o usuário permanecerá logado mesmo após fechar o aplicativo
  Future<bool> signIn(String email, String password, {bool rememberMe = false}) async {
    debugPrint('🔄 VIEWMODEL: Iniciando login para: $email (rememberMe: $rememberMe)');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final result = await _repository.signIn(email, password, rememberMe: rememberMe);
    
    return result.fold(
      (error) {
        debugPrint('❌ VIEWMODEL: Erro no login: $error');
        errorMessage = error;
        isLoading = false;
        notifyListeners();
        return false;
      },
      (user) async {
        debugPrint('✅ VIEWMODEL: Login bem-sucedido para: ${user.email}');
        currentUser = user;
        isLoading = false;
        
        // Aguardar um momento para garantir que a sessão seja estabelecida
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Recarregar o usuário para garantir que temos os dados mais recentes
        await reloadCurrentUser();
        
        return true;
      }
    );
  }
  
  /// Encerra a sessão do usuário atual
  Future<void> signOut() async {
    debugPrint('🔄 VIEWMODEL: Encerrando sessão');
    isLoading = true;
    notifyListeners();
    
    await _repository.signOut();
    
    currentUser = null;
    isLoading = false;
    notifyListeners();
    debugPrint('✅ VIEWMODEL: Sessão encerrada com sucesso');
  }
  
  /// Solicita redefinição de senha para o email fornecido
  ///
  /// Retorna true se a solicitação for bem-sucedida
  Future<bool> resetPassword(String email) async {
    debugPrint('🔄 VIEWMODEL: Solicitando redefinição de senha para: $email');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final result = await _repository.resetPassword(email);
    
    return result.fold(
      (error) {
        debugPrint('❌ VIEWMODEL: Erro na redefinição de senha: $error');
        errorMessage = error;
        isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        debugPrint('✅ VIEWMODEL: Solicitação de redefinição enviada com sucesso');
        isLoading = false;
        notifyListeners();
        return true;
      }
    );
  }
  
  /// Atualiza o perfil do usuário
  ///
  /// Retorna true se a atualização for bem-sucedida
  Future<bool> updateProfile({String? name, Map<String, dynamic>? metadata}) async {
    if (currentUser == null) {
      debugPrint('❌ VIEWMODEL: Tentativa de atualizar perfil sem usuário logado');
      errorMessage = 'Nenhum usuário logado';
      notifyListeners();
      return false;
    }
    
    debugPrint('🔄 VIEWMODEL: Atualizando perfil para: ${currentUser!.id}');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final updatedUser = currentUser!.copyWith(
      name: name,
      metadata: metadata,
    );
    
    final result = await _repository.updateProfile(updatedUser);
    
    return result.fold(
      (error) {
        debugPrint('❌ VIEWMODEL: Erro ao atualizar perfil: $error');
        errorMessage = error;
        isLoading = false;
        notifyListeners();
        return false;
      },
      (user) {
        debugPrint('✅ VIEWMODEL: Perfil atualizado com sucesso');
        currentUser = user;
        isLoading = false;
        notifyListeners();
        return true;
      }
    );
  }
  
  /// Atualiza a senha do usuário
  ///
  /// Retorna true se a atualização for bem-sucedida
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    debugPrint('🔄 VIEWMODEL: Atualizando senha');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final result = await _repository.updatePassword(currentPassword, newPassword);
    
    return result.fold(
      (error) {
        debugPrint('❌ VIEWMODEL: Erro ao atualizar senha: $error');
        errorMessage = error;
        isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        debugPrint('✅ VIEWMODEL: Senha atualizada com sucesso');
        isLoading = false;
        notifyListeners();
        return true;
      }
    );
  }
  
  /// Envia um email de verificação para o usuário atual
  ///
  /// Retorna true se o envio for bem-sucedido
  Future<bool> sendEmailVerification() async {
    debugPrint('🔄 VIEWMODEL: Enviando verificação de email');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    final result = await _repository.sendEmailVerification();
    
    return result.fold(
      (error) {
        debugPrint('❌ VIEWMODEL: Erro ao enviar verificação de email: $error');
        errorMessage = error;
        isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        debugPrint('✅ VIEWMODEL: Email de verificação enviado com sucesso');
        isLoading = false;
        notifyListeners();
        return true;
      }
    );
  }
  
  /// Verifica se o email do usuário atual está verificado
  ///
  /// Retorna true se o email estiver verificado
  Future<bool> isEmailVerified() async {
    debugPrint('🔄 VIEWMODEL: Verificando se o email está verificado');
    return await _repository.isEmailVerified();
  }
  
  @override
  void dispose() {
    debugPrint('🔄 VIEWMODEL: Liberando recursos do AuthViewModel');
    _userSubscription.cancel();
    super.dispose();
  }
}
