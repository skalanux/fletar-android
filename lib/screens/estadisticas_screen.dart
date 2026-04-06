import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_providers.dart';
import '../models/gasto.dart';

class EstadisticasScreen extends ConsumerWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthOffset = ref.watch(currentMonthProvider);
    final gastosAsync = ref.watch(gastosProvider(monthOffset));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: gastosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (gastos) => _buildChart(context, ref, gastos),
      ),
    );
  }

  Widget _buildChart(BuildContext context, WidgetRef ref, List<Gasto> gastos) {
    if (gastos.isEmpty) {
      return const Center(
        child: Text('No hay gastos este mes', style: TextStyle(color: Colors.grey)),
      );
    }

    final porCategoria = <String, double>{};
    for (final g in gastos) {
      porCategoria[g.categoria] = (porCategoria[g.categoria] ?? 0) + g.precio;
    }

    final total = porCategoria.values.fold(0.0, (a, b) => a + b);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final colors = _getColors(porCategoria.length);

    final sections = porCategoria.entries.map((e) {
      final index = porCategoria.keys.toList().indexOf(e.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: e.value,
        title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Total: ${formatter.format(total)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...porCategoria.entries.map((e) {
            final index = porCategoria.keys.toList().indexOf(e.key);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors[index % colors.length],
                  radius: 12,
                ),
                title: Text(e.key),
                trailing: Text(
                  formatter.format(e.value),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _getColors(int count) {
    final baseColors = [
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
    ];
    return baseColors.take(count).toList();
  }
}
