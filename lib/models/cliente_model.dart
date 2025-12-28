import 'dart:convert';

class ClienteModel {
  final int? id;
  final int? servidorId;
  final String nombre;
  final String direccion;
  final String telefono;
  final int? pulperiaId;
  final String? nombrePulperia;
  final double? latitude;
  final double? longitude;
  final int? usuarioId;  // Encargado (FK a users)
  final int? orden;  // Orden de visita en la ruta
  final bool sincronizado;
  final String? lastSync;
  final bool verificado;

  ClienteModel({
    this.id,
    this.servidorId,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    this.pulperiaId,
    this.nombrePulperia,
    this.latitude,
    this.longitude,
    this.usuarioId,
    this.orden,
    this.sincronizado = false,
    this.lastSync,
    this.verificado = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'servidorId': servidorId,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'pulperiaId': pulperiaId,
      'nombrePulperia': nombrePulperia,
      'latitude': latitude,
      'longitude': longitude,
      'usuarioId': usuarioId,
      'orden': orden,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
      'verificado': verificado ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': servidorId,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'pulperiaId': pulperiaId,
      'latitude': latitude,
      'longitude': longitude,
      'usuarioId': usuarioId,
      'orden': orden,
    };
  }

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id']?.toInt(),
      servidorId: map['servidorId']?.toInt(),
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'] ?? '',
      pulperiaId: map['pulperiaId']?.toInt(),
      nombrePulperia: map['nombrePulperia'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      usuarioId: map['usuarioId']?.toInt(),
      orden: map['orden']?.toInt(),
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
      verificado: map['verificado'] == 1,
    );
  }

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    // Usar servidorId como id temporal para clientes que vienen del servidor
    // Esto permite que funcionen los métodos que necesitan clienteId
    final servidorId = json['id']?.toInt();
    return ClienteModel(
      id: servidorId,  // Usar servidorId como id temporal
      servidorId: servidorId,
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      pulperiaId: json['pulperiaId']?.toInt(),
      nombrePulperia: json['nombrePulperia'],
      latitude: json['latitude'] != null
          ? (json['latitude'] is String
              ? double.tryParse(json['latitude'])
              : (json['latitude'] as num?)?.toDouble())
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is String
              ? double.tryParse(json['longitude'])
              : (json['longitude'] as num?)?.toDouble())
          : null,
      usuarioId: json['usuarioId']?.toInt(),
      orden: json['orden']?.toInt(),
      sincronizado: true,
      lastSync: DateTime.now().toIso8601String(),
      verificado: true,
    );
  }

  ClienteModel copyWith({
    int? id,
    int? servidorId,
    String? nombre,
    String? direccion,
    String? telefono,
    int? pulperiaId,
    String? nombrePulperia,
    double? latitude,
    double? longitude,
    int? usuarioId,
    int? orden,
    bool? sincronizado,
    String? lastSync,
    bool? verificado,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      servidorId: servidorId ?? this.servidorId,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      pulperiaId: pulperiaId ?? this.pulperiaId,
      nombrePulperia: nombrePulperia ?? this.nombrePulperia,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      usuarioId: usuarioId ?? this.usuarioId,
      orden: orden ?? this.orden,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
      verificado: verificado ?? this.verificado,
    );
  }
}
