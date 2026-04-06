import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../models/gasto.dart';
import '../services/widget_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthOffset = ref.watch(currentMonthProvider);
    final gastosAsync = ref.watch(gastosProvider(monthOffset));
    final monthName = _getMonthName(
      DateTime.now().add(Duration(days: 30 * monthOffset)).month,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Fletar - $monthName'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: gastosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (gastos) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final total = gastos.fold(0.0, (sum, g) => sum + g.precio);
            WidgetService.updateTotal(total);
          });
          return _buildContent(context, ref, gastos, monthOffset);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGastoDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Gasto> gastos, int monthOffset) {
    if (gastos.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gastosProvider(monthOffset));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.indigo,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Total del mes',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$0.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('No hay gastos este mes',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    }

    final total = gastos.fold(0.0, (sum, g) => sum + g.precio);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final sortedGastos = [...gastos]..sort((a, b) => b.fecha.compareTo(a.fecha));
    final recentGastos = sortedGastos.take(5).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gastosProvider(monthOffset));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.indigo,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Total del mes',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimos gastos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/gastos'),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          if (recentGastos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay gastos este mes',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            )
          else
            ...recentGastos.map((g) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      g.categoria[0].toUpperCase(),
                      style: TextStyle(color: Colors.indigo.shade700),
                    ),
                  ),
                  title: Text(g.detalle),
                  subtitle: Text('${g.categoria} • ${g.metodoPago}'),
                  trailing: Text(
                    formatter.format(g.precio),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
        ],
      ),
    );
  }

  void _showAddGastoDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddGastoSheet(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}

class AddGastoSheet extends ConsumerStatefulWidget {
  const AddGastoSheet({super.key});

  @override
  ConsumerState<AddGastoSheet> createState() => _AddGastoSheetState();
}

class _AddGastoSheetState extends ConsumerState<AddGastoSheet> {
  final _montoController = TextEditingController();
  final _detalleController = TextEditingController();
  String? _categoria;
  String? _metodoPago;
  bool _isLoading = false;

  @override
  void dispose() {
    _montoController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_montoController.text.isEmpty || _detalleController.text.isEmpty) return;
    if (_categoria == null || _metodoPago == null) return;

    setState(() => _isLoading = true);

    try {
      final gs = ref.read(sheetsServiceProvider);
      await gs.addGasto(Gasto(
        categoria: _categoria!,
        fecha: DateTime.now(),
        detalle: _detalleController.text,
        precio: double.parse(_montoController.text.replaceAll(',', '.')),
        metodoPago: _metodoPago!,
      ));
      ref.invalidate(gastosProvider(ref.read(currentMonthProvider)));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nuevo Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _montoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detalleController,
            decoration: const InputDecoration(labelText: 'Detalle'),
          ),
          const SizedBox(height: 12),
          configAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (config) => Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: (config['categories'] ?? [])
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _metodoPago,
                  decoration: const InputDecoration(labelText: 'Método de pago'),
                  items: (config['paymentMethods'] ?? [])
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _metodoPago = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Guardar'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
