import 'package:flutter/material.dart';

/// ReminderModel - Modelo de dados para representar um lembrete
///
/// Contém informações sobre o horário do lembrete e métodos para serialização/deserialização.
class ReminderModel {
  /// ID único do lembrete
  final String? id;
  
  /// ID do usuário ao qual o lembrete pertence
  final String userId;
  
  /// Horário do lembrete no formato "HH:MM"
  final String time;
  
  /// Data de criação do lembrete
  final DateTime? createdAt;
  
  /// Data de atualização do lembrete
  final DateTime? updatedAt;
  
  /// Construtor do ReminderModel
  ReminderModel({
    this.id,
    required this.userId,
    required this.time,
    this.createdAt,
    this.updatedAt,
  });
  
  /// Converter TimeOfDay para string no formato "HH:MM"
  static String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Converter string no formato "HH:MM" para TimeOfDay
  static TimeOfDay stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
  
  /// Criar uma cópia com campos atualizados
  ReminderModel copyWith({
    String? id,
    String? userId,
    String? time,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'time': time,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  /// Criar a partir de JSON
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'],
      userId: json['user_id'],
      time: json['time'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }
  
  /// Converter para TimeOfDay
  TimeOfDay toTimeOfDay() {
    return stringToTimeOfDay(time);
  }
  
  /// Criar a partir de TimeOfDay
  factory ReminderModel.fromTimeOfDay({
    String? id,
    required String userId,
    required TimeOfDay time,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Garantir que userId não seja nulo
    if (userId.isEmpty) {
      throw ArgumentError('userId não pode ser vazio');
    }
    
    return ReminderModel(
      id: id,
      userId: userId,
      time: timeOfDayToString(time),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'ReminderModel(id: $id, userId: $userId, time: $time)';
  }
}
