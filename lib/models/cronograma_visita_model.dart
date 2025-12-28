import 'dart:convert';

class CronogramaVisitaModel {
  final int? id;
  final int clienteId;
  final String diaSemana;  // lunes, martes, miércoles, jueves, viernes, sábado, domingo
  final int? orden;
  final bool activo;
  final int? servidorId;
  final bool sincronizado;
  final String? lastSync;

  CronogramaVisitaModel({
    this.id,
    required this.clienteId,
    required this.diaSemana,
    this.orden,
    this.activo = true,
    this.servidorId,
    this.sincronizado = false,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'dia_semana': diaSemana,
      'orden': orden,
      'activo': activo ? 1 : 0,
      'servidorId': servidorId,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': servidorId,
      'clienteId': clienteId,
      'dia_semana': diaSemana,
      'orden': orden,
      'activo': activo,
    };
  }

  factory CronogramaVisitaModel.fromMap(Map<String, dynamic> map) {
    return CronogramaVisitaModel(
      id: map['id']?.toInt(),
      clienteId: map['clienteId']?.toInt() ?? 0,
      diaSemana: map['dia_semana'] ?? '',
      orden: map['orden']?.toInt(),
      activo: map['activo'] == 1,
      servidorId: map['servidorId']?.toInt(),
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
    );
  }

  factory CronogramaVisitaModel.fromJson(Map<String, dynamic> json) {
    return CronogramaVisitaModel(
      id: null,
      servidorId: json['id']?.toInt(),
      clienteId: json['clienteId']?.toInt() ?? 0,
      diaSemana: json['dia_semana'] ?? '',
      orden: json['orden']?.toInt(),
      activo: json['activo'] == true || json['activo'] == 1,
      sincronizado: true,
      lastSync: DateTime.now().toIso8601String(),
    );
  }

  CronogramaVisitaModel copyWith({
    int? id,
    int? clienteId,
    String? diaSemana,
    int? orden,
    bool? activo,
    int? servidorId,
    bool? sincronizado,
    String? lastSync,
  }) {
    return CronogramaVisitaModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      diaSemana: diaSemana ?? this.diaSemana,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
      servidorId: servidorId ?? this.servidorId,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
