import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../models/gasto.dart';

class GastosScreen extends ConsumerWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthOffset = ref.watch(currentMonthProvider);
    final gastosAsync = ref.watch(gastosProvider(monthOffset));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
      ),
      body: gastosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (gastos) => _buildList(context, ref, gastos, monthOffset),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Gasto> gastos, int monthOffset) {
    if (gastos.isEmpty) {
      return const Center(
        child: Text('No hay gastos este mes', style: TextStyle(color: Colors.grey)),
      );
    }

    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('dd/MM');
    final sortedGastos = [...gastos]..sort((a, b) => b.fecha.compareTo(a.fecha));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gastosProvider(monthOffset));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedGastos.length,
        itemBuilder: (context, index) {
          final g = sortedGastos[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: Text(
                  g.categoria[0].toUpperCase(),
                  style: TextStyle(color: Colors.indigo.shade700),
                ),
              ),
              title: Text(g.detalle),
              subtitle: Text(
                '${dateFormatter.format(g.fecha)} • ${g.categoria} • ${g.metodoPago}',
              ),
              trailing: Text(
                formatter.format(g.precio),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
