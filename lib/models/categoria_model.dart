// lib/models/categoria_model.dart
import 'dart:convert';

class CategoriaModel {
  final int? id;
  final int? servidorId;
  final String nombre;
  final bool sincronizado;
  final String? lastSync;
  final bool verificado;

  CategoriaModel({
    this.id,
    this.servidorId,
    required this.nombre,
    this.sincronizado = false,
    this.lastSync,
    this.verificado = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'servidorId': servidorId,
      'nombre': nombre,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
      'verificado': verificado ? 1 : 0,
    };
  }

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] != null ? (map['id'] as num).toInt() : null,
      servidorId: map['servidorId'] != null ? (map['servidorId'] as num).toInt() : null,
      nombre: map['nombre'] ?? '',
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
      verificado: map['verificado'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoriaModel.fromJson(String source) =>
      CategoriaModel.fromMap(json.decode(source));

  CategoriaModel copyWith({
    int? id,
    int? servidorId,
    String? nombre,
    bool? sincronizado,
    String? lastSync,
    bool? verificado,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      servidorId: servidorId ?? this.servidorId,
      nombre: nombre ?? this.nombre,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
      verificado: verificado ?? this.verificado,
    );
  }



  @override
  String toString() {
    return 'CategoriaModel(id: $id, nombre: $nombre, sincronizado: $sincronizado, servidorId: $servidorId, lastSync: $lastSync, verificado: $verificado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoriaModel &&
        other.id == id &&
        other.nombre == nombre &&
        other.sincronizado == sincronizado &&
        other.servidorId == servidorId &&
        other.lastSync == lastSync &&
        other.verificado == verificado;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    nombre.hashCode ^
    sincronizado.hashCode ^
    servidorId.hashCode ^
    lastSync.hashCode ^
    verificado.hashCode;
  }
}