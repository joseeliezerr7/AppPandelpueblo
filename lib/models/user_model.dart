import 'dart:convert';

class UserModel {
  final int id;
  final String nombre;
  final String correoElectronico;
  final String telefono;
  final String permiso;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correoElectronico,
    required this.telefono,
    required this.permiso,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'],
      correoElectronico: json['correoElectronico'],
      telefono: json['telefono'],
      permiso: json['permiso'],
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nombre: map['nombre'],
      correoElectronico: map['correoElectronico'],
      telefono: map['telefono'],
      permiso: map['permiso'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correoElectronico': correoElectronico,
      'telefono': telefono,
      'permiso': permiso,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correoElectronico': correoElectronico,
      'telefono': telefono,
      'permiso': permiso,
    };
  }
}