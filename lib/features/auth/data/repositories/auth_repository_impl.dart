import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/supabase_service.dart';

/// AuthRepositoryImpl - Implementação concreta do repositório de autenticação
///
/// Utiliza o Supabase como provedor de autenticação.
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client = SupabaseService.client;
  final _userStreamController = StreamController<UserModel?>.broadcast();
  
  AuthRepositoryImpl() {
    // Ouvir mudanças de autenticação e atualizar o stream de usuários
    SupabaseService.authStateChanges.listen((authState) async {
      if (authState.event == AuthChangeEvent.signedIn ||
          authState.event == AuthChangeEvent.userUpdated) {
        final user = await getCurrentUser();
        _userStreamController.add(user);
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _userStreamController.add(null);
      }
    });
    
    // Inicializar com o usuário atual
    getCurrentUser().then((user) {
      _userStreamController.add(user);
    });
  }
  
  @override
  Stream<UserModel?> get userChanges => _userStreamController.stream;
  
  @override
  Future<Either<String, UserModel>> signUp(String email, String password, String name, {bool rememberMe = false}) async {
    try {
      debugPrint('🔍 DEBUG: Tentando cadastrar usuário: $email, nome: $name, rememberMe: $rememberMe');
      
      // Primeiro, criar o usuário
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.user == null) {
        debugPrint('❌ DEBUG: Resposta sem usuário');
        return const Left('Erro ao criar conta: resposta sem usuário');
      }
      
      // Configurar a persistência da sessão
      if (!rememberMe && response.session != null) {
        // Se rememberMe for false, configurar para não persistir a sessão
        await _client.auth.setSession(response.session!.refreshToken!);
      }
      
      debugPrint('✅ DEBUG: Usuário criado com sucesso: ${response.user!.id}');
      
      // Criar o modelo de usuário
      final user = UserModel.fromSupabaseUser(response.user!);
      
      // Atualizar o stream
      _userStreamController.add(user);
      
      return Right(user);
    } catch (e) {
      debugPrint('❌ DEBUG: Exceção ao cadastrar: $e');
      
      // Tratamento detalhado de erros
      if (e is AuthException) {
        debugPrint('❌ DEBUG: Erro do Supabase - Código: ${e.statusCode}');
        debugPrint('❌ DEBUG: Erro do Supabase - Mensagem: ${e.message}');
        
        if (e.message.contains('User already registered')) {
          return const Left('Email já cadastrado');
        } else if (e.message.contains('Password should be')) {
          return const Left('Senha muito fraca (mínimo 6 caracteres)');
        } else if (e.message.contains('Invalid email')) {
          return const Left('Email inválido');
        } else if (e.message.contains('rate limit')) {
          return const Left('Muitas tentativas. Tente novamente mais tarde.');
        }
      }
      
      return Left('Erro ao criar conta: ${e.toString()}');
    }
  }
  
  @override
  Future<Either<String, UserModel>> signIn(String email, String password, {bool rememberMe = false}) async {
    try {
      debugPrint('🔍 DEBUG: Tentando fazer login: $email, rememberMe: $rememberMe');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        debugPrint('❌ DEBUG: Resposta sem usuário');
        return const Left('Credenciais inválidas');
      }
      
      // Configurar a persistência da sessão
      if (!rememberMe && response.session != null) {
        // Se rememberMe for false, configurar para não persistir a sessão
        await _client.auth.setSession(response.session!.refreshToken!);
      }
      
      debugPrint('✅ DEBUG: Login bem-sucedido: ${response.user!.id}');
      
      // Criar o modelo de usuário
      final user = UserModel.fromSupabaseUser(response.user!);
      
      // Atualizar o stream
      _userStreamController.add(user);
      
      return Right(user);
    } catch (e) {
      debugPrint('❌ DEBUG: Exceção no login: $e');
      
      // Tratamento detalhado de erros
      if (e is AuthException) {
        debugPrint('❌ DEBUG: Erro do Supabase - Código: ${e.statusCode}');
        debugPrint('❌ DEBUG: Erro do Supabase - Mensagem: ${e.message}');
        
        // Verificar se o erro é de email não confirmado
        if (e.message.contains('Email not confirmed')) {
          debugPrint('⚠️ DEBUG: Email não confirmado, mas permitindo login');
          
          // Tentar obter o usuário atual
          final currentUser = _client.auth.currentUser;
          if (currentUser != null) {
            debugPrint('✅ DEBUG: Usuário encontrado após tentativa de login: ${currentUser.id}');
            
            // Criar o modelo de usuário
            final user = UserModel.fromSupabaseUser(currentUser);
            
            // Atualizar o stream
            _userStreamController.add(user);
            
            return Right(user);
          } else {
            debugPrint('❌ DEBUG: Não foi possível obter o usuário após tentativa de login');
            return const Left('Não foi possível completar o login. Tente novamente.');
          }
        } else if (e.message.contains('Invalid login credentials')) {
          return const Left('Email ou senha incorretos');
        } else if (e.message.contains('user not found')) {
          return const Left('Usuário não cadastrado');
        } else if (e.message.contains('invalid email')) {
          return const Left('Email inválido');
        } else if (e.message.contains('rate limit')) {
          return const Left('Muitas tentativas. Tente novamente mais tarde.');
        }
      }
      
      return Left('Erro ao fazer login: ${e.toString()}');
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      debugPrint('🔍 DEBUG: Encerrando sessão');
      await _client.auth.signOut();
      _userStreamController.add(null);
      debugPrint('✅ DEBUG: Sessão encerrada com sucesso');
    } catch (e) {
      debugPrint('❌ DEBUG: Erro ao encerrar sessão: $e');
      // Não propagamos o erro para não interromper o fluxo
    }
  }
  
  @override
  Future<Either<String, void>> resetPassword(String email) async {
    try {
      debugPrint('🔍 DEBUG: Solicitando redefinição de senha para: $email');
      await _client.auth.resetPasswordForEmail(email);
      debugPrint('✅ DEBUG: Email de redefinição enviado com sucesso');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ DEBUG: Erro ao resetar senha: $e');
      
      if (e is AuthException) {
        if (e.message.contains('user not found')) {
          return const Left('Email não cadastrado');
        } else if (e.message.contains('invalid email')) {
          return const Left('Email inválido');
        } else if (e.message.contains('rate limit')) {
          return const Left('Muitas tentativas. Tente novamente mais tarde.');
        }
      }
      
      return Left('Erro ao recuperar senha: ${e.toString()}');
    }
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      debugPrint('🔍 DEBUG: Verificando usuário atual');
      
      // Verificar a sessão atual primeiro
      final session = _client.auth.currentSession;
      if (session != null) {
        debugPrint('✅ DEBUG: Sessão atual encontrada: ${session.user.id}');
      } else {
        debugPrint('⚠️ DEBUG: Nenhuma sessão atual encontrada');
      }
      
      // Verificar o usuário atual
      final user = _client.auth.currentUser;
      if (user != null) {
        debugPrint('✅ DEBUG: Usuário atual encontrado: ${user.id}');
        debugPrint('✅ DEBUG: Email: ${user.email}');
        debugPrint('✅ DEBUG: Metadados: ${user.userMetadata}');
        
        return UserModel.fromSupabaseUser(user);
      } else {
        debugPrint('⚠️ DEBUG: Nenhum usuário atual encontrado');
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ DEBUG: Erro ao obter usuário atual: $e');
      return null;
    }
  }
  
  @override
  Future<Either<String, UserModel>> updateProfile(UserModel user) async {
    try {
      debugPrint('🔍 DEBUG: Atualizando perfil para usuário: ${user.id}');
      
      final response = await _client.auth.updateUser(
        UserAttributes(
          data: {
            'name': user.name,
            ...?user.metadata,
          },
        ),
      );
      
      if (response.user == null) {
        debugPrint('❌ DEBUG: Resposta sem usuário');
        return const Left('Erro ao atualizar perfil');
      }
      
      debugPrint('✅ DEBUG: Perfil atualizado com sucesso');
      
      final updatedUser = UserModel.fromSupabaseUser(response.user!);
      _userStreamController.add(updatedUser);
      
      return Right(updatedUser);
    } catch (e) {
      debugPrint('❌ DEBUG: Erro ao atualizar perfil: $e');
      return Left('Erro ao atualizar perfil: ${e.toString()}');
    }
  }
  
  @override
  Future<Either<String, void>> updatePassword(String currentPassword, String newPassword) async {
    try {
      debugPrint('🔍 DEBUG: Atualizando senha');
      
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      debugPrint('✅ DEBUG: Senha atualizada com sucesso');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ DEBUG: Erro ao atualizar senha: $e');
      return Left('Erro ao atualizar senha: ${e.toString()}');
    }
  }
  
  @override
  Future<Either<String, void>> sendEmailVerification() async {
    try {
      debugPrint('🔍 DEBUG: Enviando verificação de email');
      
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ DEBUG: Nenhum usuário logado');
        return const Left('Nenhum usuário logado');
      }
      
      // O Supabase não tem um método direto para isso, mas podemos usar o OTP
      // para enviar um email de verificação
      await _client.auth.signInWithOtp(
        email: user.email!,
      );
      
      debugPrint('✅ DEBUG: Email de verificação enviado com sucesso');
      return const Right(null);
    } catch (e) {
      debugPrint('❌ DEBUG: Erro ao enviar verificação de email: $e');
      return Left('Erro ao enviar verificação de email: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> isEmailVerified() async {
    try {
      debugPrint('🔍 DEBUG: Verificando se o email está verificado');
      
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ DEBUG: Nenhum usuário logado');
        return false;
      }
      
      // Verificar se o email está verificado
      final isVerified = user.emailConfirmedAt != null;
      
      if (isVerified) {
        debugPrint('✅ DEBUG: Email verificado');
      } else {
        debugPrint('⚠️ DEBUG: Email não verificado');
      }
      
      return isVerified;
    } catch (e) {
      debugPrint('❌ DEBUG: Erro ao verificar email: $e');
      return false;
    }
  }
  
  /// Método para limpar recursos
  void dispose() {
    _userStreamController.close();
  }
}
