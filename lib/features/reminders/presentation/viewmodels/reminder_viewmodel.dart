import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

/// ReminderViewModel - ViewModel para gerenciar os lembretes
///
/// Gerencia o estado dos lembretes e fornece métodos para interagir com o Supabase.
class ReminderViewModel extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  
  /// Lista de lembretes (horários)
  List<TimeOfDay> _reminders = [
    const TimeOfDay(hour: 9, minute: 0),
  ];
  
  /// Indica se uma operação está em andamento
  bool isLoading = false;
  
  /// Mensagem de erro, se houver
  String? errorMessage;
  
  /// Construtor do ReminderViewModel
  ReminderViewModel() {
    _loadReminders();
  }
  
  /// Obtém a lista de lembretes
  List<TimeOfDay> get reminders => List.unmodifiable(_reminders);
  
  /// Carrega os lembretes do usuário atual
  Future<void> _loadReminders() async {
    try {
      debugPrint('🔄 VIEWMODEL: Carregando lembretes...');
      
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ VIEWMODEL: Nenhum usuário logado');
        isLoading = false;
        notifyListeners();
        return;
      }
      
      final response = await _client
          .from('reminders')
          .select()
          .eq('user_id', user.id)
          .order('time');
      
      final List<TimeOfDay> loadedReminders = [];
      
      for (final item in response as List) {
        final timeString = item['time'] as String;
        final parts = timeString.split(':');
        loadedReminders.add(
          TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ),
        );
      }
      
      if (loadedReminders.isNotEmpty) {
        _reminders = loadedReminders;
      }
      
      debugPrint('✅ VIEWMODEL: ${_reminders.length} lembretes carregados');
    } catch (e) {
      debugPrint('❌ VIEWMODEL: Erro ao carregar lembretes: $e');
      errorMessage = 'Erro ao carregar lembretes: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  /// Adiciona um novo lembrete
  void addReminder(TimeOfDay time) {
    _reminders.add(time);
    notifyListeners();
  }
  
  /// Remove um lembrete pelo índice
  void removeReminder(int index) {
    if (index >= 0 && index < _reminders.length) {
      _reminders.removeAt(index);
      notifyListeners();
    }
  }
  
  /// Atualiza um lembrete existente
  void updateReminder(int index, TimeOfDay newTime) {
    if (index >= 0 && index < _reminders.length) {
      _reminders[index] = newTime;
      notifyListeners();
    }
  }
  
  /// Salva os lembretes no Supabase
  Future<bool> saveReminders() async {
    try {
      debugPrint('🔄 VIEWMODEL: Salvando ${_reminders.length} lembretes...');
      
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ VIEWMODEL: Nenhum usuário logado');
        errorMessage = 'Nenhum usuário logado';
        isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Primeiro, excluir todos os lembretes existentes
      await _client
          .from('reminders')
          .delete()
          .eq('user_id', user.id);
      
      // Preparar dados para inserção em massa
      final List<Map<String, dynamic>> dataToInsert = [];
      
      for (final time in _reminders) {
        final hour = time.hour.toString().padLeft(2, '0');
        final minute = time.minute.toString().padLeft(2, '0');
        final timeString = '$hour:$minute';
        
        dataToInsert.add({
          'time': timeString,
          'user_id': user.id,
        });
      }
      
      if (dataToInsert.isNotEmpty) {
        await _client
            .from('reminders')
            .insert(dataToInsert);
      }
      
      debugPrint('✅ VIEWMODEL: Lembretes salvos com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ VIEWMODEL: Erro ao salvar lembretes: $e');
      errorMessage = 'Erro ao salvar lembretes: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
