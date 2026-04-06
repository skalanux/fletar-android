import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../models/gasto.dart';

class VencimientosScreen extends ConsumerWidget {
  const VencimientosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vencimientosAsync = ref.watch(vencimientosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vencimientos'),
      ),
      body: vencimientosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vencimientos) => _buildList(context, ref, vencimientos),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Vencimiento> vencimientos) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('dd/MM');
    final sortedVenc = [...vencimientos]..sort((a, b) => a.fecha.compareTo(b.fecha));

    final pendiente = sortedVenc.where((v) => !v.pagado).toList();
    final pagado = sortedVenc.where((v) => v.pagado).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(vencimientosProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          if (pendiente.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pendientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...pendiente.map((v) => Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.warning, color: Colors.white),
                    ),
                    title: Text(v.nombre),
                    subtitle: Text(dateFormatter.format(v.fecha)),
                    trailing: Text(
                      formatter.format(v.valor),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )),
          ],
          if (pagado.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pagados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...pagado.map((v) => Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text(v.nombre),
                    subtitle: Text(dateFormatter.format(v.fecha)),
                    trailing: Text(
                      formatter.format(v.valor),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
