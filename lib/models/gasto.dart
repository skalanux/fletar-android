class Gasto {
  final String categoria;
  final DateTime fecha;
  final String detalle;
  final double precio;
  final String metodoPago;
  final String cuotas;

  Gasto({
    required this.categoria,
    required this.fecha,
    required this.detalle,
    required this.precio,
    required this.metodoPago,
    this.cuotas = '',
  });

  factory Gasto.fromSheetRow(List<dynamic> row) {
    return Gasto(
      categoria: row.isNotEmpty ? row[0].toString() : '',
      fecha: row.length > 1 ? _parseDate(row[1].toString()) : DateTime.now(),
      detalle: row.length > 2 ? row[2].toString() : '',
      precio: row.length > 3 ? _parseNumber(row[3].toString()) : 0.0,
      metodoPago: row.length > 4 ? row[4].toString() : '',
      cuotas: row.length > 5 ? row[5].toString() : '',
    );
  }

  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  static double _parseNumber(String numStr) {
    try {
      return double.parse(numStr.replaceAll(',', '.'));
    } catch (_) {
      return 0.0;
    }
  }

  List<dynamic> toSheetRow() {
    return [
      categoria,
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
      detalle,
      precio.toString(),
      metodoPago,
      cuotas,
    ];
  }
}

class Vencimiento {
  final String nombre;
  final DateTime fecha;
  final double valor;
  final double? dolares;
  final double? uva;
  final bool pagado;

  Vencimiento({
    required this.nombre,
    required this.fecha,
    required this.valor,
    this.dolares,
    this.uva,
    this.pagado = false,
  });

  factory Vencimiento.fromSheetRow(List<dynamic> row) {
    return Vencimiento(
      nombre: row.isNotEmpty ? row[0].toString() : '',
      fecha: row.length > 2 ? _parseDate(row[2].toString()) : DateTime.now(),
      valor: row.length > 3 ? _parseNumber(row[3].toString()) : 0.0,
      dolares: row.length > 4 && row[4].toString().isNotEmpty
          ? _parseNumber(row[4].toString())
          : null,
      uva: row.length > 5 && row[5].toString().isNotEmpty
          ? _parseNumber(row[5].toString())
          : null,
      pagado: row.length > 7 && row[7].toString().toLowerCase() == 'si',
    );
  }

  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  static double _parseNumber(String numStr) {
    try {
      return double.parse(numStr.replaceAll(',', '.'));
    } catch (_) {
      return 0.0;
    }
  }
}
