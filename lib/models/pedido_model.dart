import 'dart:convert';

class PedidoModel {
  final int? id;
  final int? servidorId;
  final int clienteId;
  final String? nombreCliente;
  final int? pulperiaId;
  final String? nombrePulperia;
  final String fecha;
  final double total;
  final bool sincronizado;
  final String? lastSync;
  final bool verificado;
  final List<DetallePedidoModel>? detalles;

  PedidoModel({
    this.id,
    this.servidorId,
    required this.clienteId,
    this.nombreCliente,
    this.pulperiaId,
    this.nombrePulperia,
    required this.fecha,
    required this.total,
    this.sincronizado = false,
    this.lastSync,
    this.verificado = true,
    this.detalles,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'servidorId': servidorId,
      'clienteId': clienteId,
      'nombreCliente': nombreCliente,
      'pulperiaId': pulperiaId,
      'nombrePulperia': nombrePulperia,
      'fecha': fecha,
      'total': total,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
      'verificado': verificado ? 1 : 0,
    };
  }

  factory PedidoModel.fromMap(Map<String, dynamic> map) {
    return PedidoModel(
      id: map['id']?.toInt(),
      servidorId: map['servidorId']?.toInt(),
      clienteId: map['clienteId']?.toInt() ?? 0,
      nombreCliente: map['nombreCliente'],
      pulperiaId: map['pulperiaId']?.toInt(),
      nombrePulperia: map['nombrePulperia'],
      fecha: map['fecha'] ?? '',
      total: map['total']?.toDouble() ?? 0.0,
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
      verificado: map['verificado'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory PedidoModel.fromJson(String source) =>
      PedidoModel.fromMap(json.decode(source));

  PedidoModel copyWith({
    int? id,
    int? servidorId,
    int? clienteId,
    String? nombreCliente,
    int? pulperiaId,
    String? nombrePulperia,
    String? fecha,
    double? total,
    bool? sincronizado,
    String? lastSync,
    bool? verificado,
    List<DetallePedidoModel>? detalles,
  }) {
    return PedidoModel(
      id: id ?? this.id,
      servidorId: servidorId ?? this.servidorId,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      pulperiaId: pulperiaId ?? this.pulperiaId,
      nombrePulperia: nombrePulperia ?? this.nombrePulperia,
      fecha: fecha ?? this.fecha,
      total: total ?? this.total,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
      verificado: verificado ?? this.verificado,
      detalles: detalles ?? this.detalles,
    );
  }
}

class DetallePedidoModel {
  final int? id;
  final int? servidorId;
  final int? pedidoId;
  final int productoId;
  final String? nombreProducto;
  final int cantidad;
  final double precio;
  final bool sincronizado;
  final String? lastSync;

  DetallePedidoModel({
    this.id,
    this.servidorId,
    this.pedidoId,
    required this.productoId,
    this.nombreProducto,
    required this.cantidad,
    required this.precio,
    this.sincronizado = false,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'servidorId': servidorId,
      'pedidoId': pedidoId,
      'productoId': productoId,
      'nombreProducto': nombreProducto,
      'cantidad': cantidad,
      'precio': precio,
      'sincronizado': sincronizado ? 1 : 0,
      'last_sync': lastSync,
    };
  }

  factory DetallePedidoModel.fromMap(Map<String, dynamic> map) {
    return DetallePedidoModel(
      id: map['id']?.toInt(),
      servidorId: map['servidorId']?.toInt(),
      pedidoId: map['pedidoId']?.toInt(),
      productoId: map['productoId']?.toInt() ?? 0,
      nombreProducto: map['nombreProducto'],
      cantidad: map['cantidad']?.toInt() ?? 0,
      precio: map['precio']?.toDouble() ?? 0.0,
      sincronizado: map['sincronizado'] == 1,
      lastSync: map['last_sync'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DetallePedidoModel.fromJson(String source) =>
      DetallePedidoModel.fromMap(json.decode(source));

  DetallePedidoModel copyWith({
    int? id,
    int? servidorId,
    int? pedidoId,
    int? productoId,
    String? nombreProducto,
    int? cantidad,
    double? precio,
    bool? sincronizado,
    String? lastSync,
  }) {
    return DetallePedidoModel(
      id: id ?? this.id,
      servidorId: servidorId ?? this.servidorId,
      pedidoId: pedidoId ?? this.pedidoId,
      productoId: productoId ?? this.productoId,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
      sincronizado: sincronizado ?? this.sincronizado,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  double get subtotal => cantidad * precio;
}
