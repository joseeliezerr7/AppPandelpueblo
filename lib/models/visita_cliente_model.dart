import 'dart:convert';

class VisitaClienteModel {
  final int? id;
  final int clienteId;
  final String fecha;
  final bool realizada;
  final String? notas;
  final int? servidorId;
  final bool sincronizado;
  final String? lastSync;

  VisitaClienteModel({
    this.id,
    required this.clienteId,
    required this.fecha,
    this.realizada = false,
    this.notas,
    this.servidorId,
    this.sincronizado = false,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'fecha': fecha,
      'realizada': realizada ? 1 : 0,
      'notas': notas,
      'servidorId': servidorId,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': servidorId,
      'clienteId': clienteId,
      'fecha': fecha,
      'realizada': realizada,
      'notas': notas,
    };
  }

  factory VisitaClienteModel.fromMap(Map<String, dynamic> map) {
    return VisitaClienteModel(
      id: map['id']?.toInt(),
      clienteId: map['clienteId']?.toInt() ?? 0,
      fecha: map['fecha'] ?? '',
      realizada: map['realizada'] == 1,
      notas: map['notas'],
      servidorId: map['servidorId']?.toInt(),
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
    );
  }

  factory VisitaClienteModel.fromJson(Map<String, dynamic> json) {
    return VisitaClienteModel(
      id: null,
      servidorId: json['id']?.toInt(),
      clienteId: json['clienteId']?.toInt() ?? 0,
      fecha: json['fecha'] ?? '',
      realizada: json['realizada'] == true || json['realizada'] == 1,
      notas: json['notas'],
      sincronizado: true,
      lastSync: DateTime.now().toIso8601String(),
    );
  }

  VisitaClienteModel copyWith({
    int? id,
    int? clienteId,
    String? fecha,
    bool? realizada,
    String? notas,
    int? servidorId,
    bool? sincronizado,
    String? lastSync,
  }) {
    return VisitaClienteModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      fecha: fecha ?? this.fecha,
      realizada: realizada ?? this.realizada,
      notas: notas ?? this.notas,
      servidorId: servidorId ?? this.servidorId,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
