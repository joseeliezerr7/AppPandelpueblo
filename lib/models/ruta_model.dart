import 'dart:convert';

class RutaModel {
  final int? id;
  final int? servidorId;
  final String nombre;
  final int cantidadPulperias;
  final int cantidadClientes;
  final bool sincronizado;
  final String? lastSync;
  final bool verificado;

  RutaModel({
    this.id,
    this.servidorId,
    required this.nombre,
    this.cantidadPulperias = 0,
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
      'cantidadPulperias': cantidadPulperias,
      'cantidadClientes': cantidadClientes,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
      'verificado': verificado ? 1 : 0,
    };
  }

  factory RutaModel.fromMap(Map<String, dynamic> map) {
    return RutaModel(
      id: map['id']?.toInt(),
      servidorId: map['servidorId']?.toInt(),
      nombre: map['nombre'] ?? '',
      cantidadPulperias: map['cantidadPulperias']?.toInt() ?? 0,
      cantidadClientes: map['cantidadClientes']?.toInt() ?? 0,
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
      verificado: map['verificado'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory RutaModel.fromJson(String source) =>
      RutaModel.fromMap(json.decode(source));

  RutaModel copyWith({
    int? id,
    int? servidorId,
    String? nombre,
    int? cantidadPulperias,
    int? cantidadClientes,
    bool? sincronizado,
    String? lastSync,
    bool? verificado,
  }) {
    return RutaModel(
      id: id ?? this.id,
      servidorId: servidorId ?? this.servidorId,
      nombre: nombre ?? this.nombre,
      cantidadPulperias: cantidadPulperias ?? this.cantidadPulperias,
      cantidadClientes: cantidadClientes ?? this.cantidadClientes,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
      verificado: verificado ?? this.verificado,
    );
  }
}