import 'dart:convert';

class ProductoModel {
  int? id;  // Este será el ID tanto local como del servidor
  String nombre;
  double precioCompra;
  double precioVenta;
  int cantidad;
  int categoriaId;
  bool sincronizado;

  ProductoModel({
    this.id,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.cantidad,
    required this.categoriaId,
    this.sincronizado = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'precioCompra': precioCompra,
      'precioVenta': precioVenta,
      'cantidad': cantidad,
      'categoriaId': categoriaId,
      'sincronizado': sincronizado ? 1 : 0,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Convertir a JSON string
  String toJson() {
    return json.encode({
      'id': id,
      'nombre': nombre,
      'precioCompra': precioCompra,
      'precioVenta': precioVenta,
      'cantidad': cantidad,
      'categoriaId': categoriaId,
      'sincronizado': sincronizado,
    });
  }

  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id'],
      nombre: map['nombre'],
      precioCompra: double.parse(map['precioCompra'].toString()),
      precioVenta: double.parse(map['precioVenta'].toString()),
      cantidad: int.parse(map['cantidad'].toString()),
      categoriaId: int.parse(map['categoriaId'].toString()),
      sincronizado: map['sincronizado'] == 1 || map['sincronizado'] == true,
    );
  }

  // Crear desde JSON string
  factory ProductoModel.fromJson(String source) {
    final Map<String, dynamic> json = jsonDecode(source);
    return ProductoModel(
      id: json['id'],
      nombre: json['nombre'],
      precioCompra: double.parse(json['precioCompra'].toString()),
      precioVenta: double.parse(json['precioVenta'].toString()),
      cantidad: int.parse(json['cantidad'].toString()),
      categoriaId: int.parse(json['categoriaId'].toString()),
      sincronizado: json['sincronizado'] ?? false,
    );
  }

  factory ProductoModel.fromApi(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id'],
      nombre: json['nombre'],
      precioCompra: double.parse(json['precioCompra'].toString()),
      precioVenta: double.parse(json['precioVenta'].toString()),
      cantidad: int.parse(json['cantidad'].toString()),
      categoriaId: int.parse(json['categoriaId'].toString()),
      sincronizado: true,
    );
  }

  Map<String, dynamic> toApi() {
    return {
      'nombre': nombre,
      'precioCompra': precioCompra,
      'precioVenta': precioVenta,
      'cantidad': cantidad,
      'categoriaId': categoriaId,
    };
  }
}