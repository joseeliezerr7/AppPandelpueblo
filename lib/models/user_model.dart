import 'dart:convert';

class UserModel {
  final int id;
  final String nombre;
  final String correoElectronico;
  final String telefono;
  final String permiso;
  final int? rutaId;
  final String? nombreRuta;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correoElectronico,
    required this.telefono,
    required this.permiso,
    this.rutaId,
    this.nombreRuta,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'],
      correoElectronico: json['correoElectronico'],
      telefono: json['telefono'],
      permiso: json['permiso'],
      rutaId: json['rutaId'],
      nombreRuta: json['nombreRuta'],
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nombre: map['nombre'],
      correoElectronico: map['correoElectronico'],
      telefono: map['telefono'],
      permiso: map['permiso'],
      rutaId: map['rutaId'],
      nombreRuta: map['nombreRuta'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correoElectronico': correoElectronico,
      'telefono': telefono,
      'permiso': permiso,
      'rutaId': rutaId,
      'nombreRuta': nombreRuta,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correoElectronico': correoElectronico,
      'telefono': telefono,
      'permiso': permiso,
      'rutaId': rutaId,
      'nombreRuta': nombreRuta,
    };
  }

  UserModel copyWith({
    int? id,
    String? nombre,
    String? correoElectronico,
    String? telefono,
    String? permiso,
    int? rutaId,
    String? nombreRuta,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      telefono: telefono ?? this.telefono,
      permiso: permiso ?? this.permiso,
      rutaId: rutaId ?? this.rutaId,
      nombreRuta: nombreRuta ?? this.nombreRuta,
    );
  }
}