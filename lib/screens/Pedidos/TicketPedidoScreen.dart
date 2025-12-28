import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pedido_model.dart';

class TicketPedidoScreen extends StatelessWidget {
  final PedidoModel pedido;

  const TicketPedidoScreen({
    Key? key,
    required this.pedido,
  }) : super(key: key);

  String _formatFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket de Pedido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implementar compartir ticket
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de compartir próximamente'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implementar imprimir ticket
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de impresión próximamente'),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 80 * 3.78, // 80mm convertido a pixels aprox (302px)
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Encabezado
                  const Text(
                    'PAN DEL PUEBLO',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'TICKET DE PEDIDO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(thickness: 2, height: 24),

                  // Información del pedido
                  _buildInfoRow('Fecha:', _formatFecha(pedido.fecha)),
                  if (pedido.id != null)
                    _buildInfoRow('No. Pedido:', '#${pedido.id}'),
                  const SizedBox(height: 8),

                  // Cliente
                  _buildInfoRow('Cliente:', pedido.nombreCliente ?? 'N/A'),
                  if (pedido.nombrePulperia != null)
                    _buildInfoRow('Pulpería:', pedido.nombrePulperia!),

                  const Divider(thickness: 1, height: 24),

                  // Detalles del pedido
                  const Text(
                    'DETALLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Encabezado de tabla
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Producto',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 40,
                        child: Text(
                          'Cant.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(
                        width: 50,
                        child: Text(
                          'Precio',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1, height: 12),

                  // Items
                  if (pedido.detalles != null)
                    ...pedido.detalles!.map((detalle) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  detalle.nombreProducto ?? 'Producto',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${detalle.cantidad}',
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  'L ${detalle.precio.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  'L ${detalle.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        )),

                  const Divider(thickness: 2, height: 16),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'L ${pedido.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Divider(thickness: 2, height: 24),

                  // Pie de página
                  const Text(
                    '¡Gracias por su compra!',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generado el ${_formatFecha(DateTime.now().toIso8601String())}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check),
          label: const Text('Cerrar'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
