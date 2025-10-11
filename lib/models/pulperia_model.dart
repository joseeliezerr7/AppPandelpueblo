import 'dart:convert';

class PulperiaModel {
  final int? id;
  final int? servidorId;
  final String nombre;
  final String direccion;
  final String telefono;
  final int? rutaId;
  final String? nombreRuta;
  final int orden;
  final int cantidadClientes;
  final bool sincronizado;
  final String? lastSync;
  final bool verificado;

  PulperiaModel({
    this.id,
    this.servidorId,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    this.rutaId,
    this.nombreRuta,
    this.orden = 0,
    this.cantidadClientes = 0,
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
      'rutaId': rutaId,
      'nombreRuta': nombreRuta,
      'orden': orden,
      'cantidadClientes': cantidadClientes,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
      'verificado': verificado ? 1 : 0,
    };
  }

  factory PulperiaModel.fromMap(Map<String, dynamic> map) {
    return PulperiaModel(
      id: map['id']?.toInt(),
      servidorId: map['servidorId']?.toInt(),
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'] ?? '',
      rutaId: map['rutaId']?.toInt(),
      nombreRuta: map['nombreRuta'],
      orden: map['orden']?.toInt() ?? 0,
      cantidadClientes: map['cantidadClientes']?.toInt() ?? 0,
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
      verificado: map['verificado'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory PulperiaModel.fromJson(String source) =>
      PulperiaModel.fromMap(json.decode(source));

  PulperiaModel copyWith({
    int? id,
    int? servidorId,
    String? nombre,
    String? direccion,
    String? telefono,
    int? rutaId,
    String? nombreRuta,
    int? orden,
    int? cantidadClientes,
    bool? sincronizado,
    String? lastSync,
    bool? verificado,
  }) {
    return PulperiaModel(
      id: id ?? this.id,
      servidorId: servidorId ?? this.servidorId,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      rutaId: rutaId ?? this.rutaId,
      nombreRuta: nombreRuta ?? this.nombreRuta,
      orden: orden ?? this.orden,
      cantidadClientes: cantidadClientes ?? this.cantidadClientes,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
      verificado: verificado ?? this.verificado,
    );
  }
}