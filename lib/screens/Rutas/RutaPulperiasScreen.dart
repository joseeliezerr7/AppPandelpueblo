import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ruta_model.dart';
import '../../models/cliente_model.dart';
import '../../models/pedido_model.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/cronograma_visita_provider.dart';
import '../../providers/visita_cliente_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/pulperia_model.dart';
import '../Pulperias/NuevoPedidoScreen.dart';

class RutaPulperiasScreen extends StatefulWidget {
  final RutaModel ruta;

  const RutaPulperiasScreen({
    Key? key,
    required this.ruta,
  }) : super(key: key);

  @override
  State<RutaPulperiasScreen> createState() => _RutaPulperiasScreenState();
}

class _RutaPulperiasScreenState extends State<RutaPulperiasScreen> {
  String _searchQuery = '';
  String _filtroSeleccionado = 'Todas'; // Todas, Visitadas Hoy, Pendientes
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<ClienteModel> _clientes = [];

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClientes() async {
    try {
      setState(() => _isLoading = true);

      final clienteProvider = context.read<ClienteProvider>();

      // Cargar clientes de la ruta seleccionada
      if (widget.ruta.servidorId != null) {
        _clientes = await clienteProvider.loadClientesPorRuta(widget.ruta.servidorId!);
      } else if (widget.ruta.id != null) {
        // Si solo tiene ID local, intentar cargar todos y filtrar
        // (esto solo debería pasar en casos muy específicos)
        await clienteProvider.loadClientes();
        _clientes = clienteProvider.clientes;
      }

      _clientes.sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error al cargar clientes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verCronogramaVisitas(ClienteModel cliente) async {
    final cronogramaProvider = context.read<CronogramaVisitaProvider>();
    await cronogramaProvider.loadCronogramasPorCliente(cliente.id!);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text('Cronograma de ${cliente.nombre}')),
          ],
        ),
        content: cronogramaProvider.cronogramas.isEmpty
            ? const Text('No hay días de visita programados')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Días de visita:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...cronogramaProvider.cronogramas
                      .where((c) => c.activo)
                      .map((cronograma) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  cronograma.diaSemana,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _verHistorialVisitas(ClienteModel cliente) async {
    final visitaProvider = context.read<VisitaClienteProvider>();
    await visitaProvider.loadVisitasPorCliente(cliente.id!);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Historial de Visitas - ${cliente.nombre}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visitaProvider.visitas.isEmpty
                      ? const Center(child: Text('No hay visitas registradas'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: visitaProvider.visitas.length,
                          itemBuilder: (context, index) {
                            final visita = visitaProvider.visitas[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: visita.realizada ? Colors.green : Colors.orange,
                                child: Icon(
                                  visita.realizada ? Icons.check : Icons.schedule,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                _formatFecha(visita.fecha),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    visita.realizada ? 'Realizada' : 'Pendiente',
                                    style: TextStyle(
                                      color: visita.realizada ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (visita.notas != null && visita.notas!.isNotEmpty)
                                    Text(
                                      visita.notas!,
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _verHistorialPedidos(ClienteModel cliente) async {
    final pedidoProvider = context.read<PedidoProvider>();
    final pedidos = await pedidoProvider.loadPedidosPorCliente(cliente.id!);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Historial de ${cliente.nombre}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: pedidos.isEmpty
                      ? const Center(child: Text('No hay pedidos registrados'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: pedidos.length,
                          itemBuilder: (context, index) {
                            final pedido = pedidos[index];
                            return ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                'Pedido del ${_formatFecha(pedido.fecha)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Total: L ${pedido.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: [
                                if (pedido.detalles != null && pedido.detalles!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: pedido.detalles!.map((detalle) {
                                        return ListTile(
                                          dense: true,
                                          title: Text(detalle.nombreProducto ?? 'Producto'),
                                          subtitle: Text(
                                            '${detalle.cantidad} x L ${detalle.precio.toStringAsFixed(2)}',
                                          ),
                                          trailing: Text(
                                            'L ${detalle.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruta.nombre),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${_clientes.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Información de la ruta
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.route, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ruta.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_clientes.length} clientes (pulperías)',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Buscador
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente/pulpería...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Lista de clientes
                Expanded(
                  child: _buildClientesList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadClientes,
        label: const Text('Actualizar'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildClientesList() {
    var clientesFiltrados = _clientes;

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      clientesFiltrados = clientesFiltrados.where((c) {
        return c.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               c.direccion.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (clientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron resultados'
                  : 'No hay clientes en esta ruta',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: clientesFiltrados.length,
      itemBuilder: (context, index) {
        final cliente = clientesFiltrados[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                '${cliente.orden ?? index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              cliente.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cliente.direccion),
                Text(
                  'Tel: ${cliente.telefono}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (cliente.latitude != null && cliente.longitude != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${cliente.latitude!.toStringAsFixed(4)}, ${cliente.longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Cronograma'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade900,
                      ),
                      onPressed: () => _verCronogramaVisitas(cliente),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.event_available, size: 18),
                      label: const Text('Visitas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.purple.shade900,
                      ),
                      onPressed: () => _verHistorialVisitas(cliente),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Pedidos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade100,
                        foregroundColor: Colors.orange.shade900,
                      ),
                      onPressed: () => _verHistorialPedidos(cliente),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Nuevo Pedido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green.shade900,
                      ),
                      onPressed: () async {
                        // Crear un PulperiaModel dummy desde el cliente
                        final pulperiaDummy = PulperiaModel(
                          id: cliente.pulperiaId,
                          nombre: cliente.nombrePulperia ?? cliente.nombre,
                          direccion: cliente.direccion,
                          telefono: cliente.telefono,
                        );

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NuevoPedidoScreen(
                              cliente: cliente,
                              pulperia: pulperiaDummy,
                            ),
                          ),
                        );
                        _loadClientes();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }
}
