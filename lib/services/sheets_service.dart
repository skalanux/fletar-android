import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gasto.dart';

class SheetsService {
  static const _scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
  ];

  GoogleSignIn? _googleSignIn;
  http.Client? _client;
  sheets.SheetsApi? _sheetsApi;
  String? _spreadsheetUrl;
  String? _spreadsheetId;

  bool get isAuthenticated => _sheetsApi != null;
  String? get spreadsheetUrl => _spreadsheetUrl;

  Future<void> init(GoogleSignIn googleSignIn) async {
    _googleSignIn = googleSignIn;
    final prefs = await SharedPreferences.getInstance();
    _spreadsheetUrl = prefs.getString('spreadsheet_url');
    debugPrint('URL cargada desde SharedPreferences: $_spreadsheetUrl');
    if (_spreadsheetUrl != null) {
      _spreadsheetId = _extractSpreadsheetId(_spreadsheetUrl!);
      debugPrint('Spreadsheet ID extraído: $_spreadsheetId');
    }
  }

  Future<void> signIn() async {
    final user = await _googleSignIn!.signIn();
    if (user != null) {
      final auth = await user.authHeaders;
      _client = _GoogleAuthClient(auth);
      _sheetsApi = sheets.SheetsApi(_client!);
    }
  }

  Future<void> setAuthenticatedClient(Map<String, String> auth) async {
    _client = _GoogleAuthClient(auth);
    _sheetsApi = sheets.SheetsApi(_client!);
  }

  Future<void> setSpreadsheetUrl(String url) async {
    _spreadsheetUrl = url;
    _spreadsheetId = _extractSpreadsheetId(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spreadsheet_url', url);
    debugPrint('URL guardada en SharedPreferences: $url');
  }

  String? _extractSpreadsheetId(String url) {
    final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)').firstMatch(url);
    return match?.group(1);
  }

  Future<Map<String, List<String>>> getConfig() async {
    if (_sheetsApi == null || _spreadsheetId == null) {
      throw Exception('No autenticado');
    }

    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId!,
        'Configuraciones',
      );

      final categories = <String>[];
      final paymentMethods = <String>[];

      if (response.values != null && response.values!.isNotEmpty) {
        // Skip header row
        for (int i = 1; i < response.values!.length; i++) {
          final row = response.values![i];
          if (row is List && row.isNotEmpty) {
            if (row[0].toString().isNotEmpty) {
              categories.add(row[0].toString());
            }
            if (row.length > 1 && row[1].toString().isNotEmpty) {
              paymentMethods.add(row[1].toString());
            }
          }
        }
      }

      return {
        'categories': categories,
        'paymentMethods': paymentMethods,
      };
    } catch (e) {
      debugPrint('Error getting config: $e');
      return {'categories': [], 'paymentMethods': []};
    }
  }

  Future<List<Gasto>> getGastos({int monthOffset = 0}) async {
    if (_sheetsApi == null || _spreadsheetId == null) {
      throw Exception('No autenticado');
    }

    final now = DateTime.now().add(Duration(days: 30 * monthOffset));
    final month = now.month;
    final year = now.year;

    try {
      // Try with a broader range first
      var response = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId!,
        'Gastos',
      );

      if (response.values == null || response.values!.isEmpty) {
        return [];
      }

      final gastos = <Gasto>[];
      // Skip header row (row 1), start from row 2
      for (int i = 1; i < response.values!.length; i++) {
        final row = response.values![i];
        if (row is List && row.isNotEmpty) {
          // Check if row has enough data (at least 4 columns)
          if (row.length >= 4 && row[0].toString().isNotEmpty) {
            try {
              final gasto = Gasto.fromSheetRow(row);
              if (gasto.fecha.month == month && gasto.fecha.year == year) {
                gastos.add(gasto);
              }
            } catch (e) {
              debugPrint('Error parsing row $i: $row, error: $e');
            }
          }
        }
      }

      return gastos;
    } catch (e) {
      debugPrint('Error getting gastos: $e');
      return [];
    }
  }

  Future<void> addGasto(Gasto gasto) async {
    if (_sheetsApi == null || _spreadsheetId == null) {
      throw Exception('No autenticado');
    }

    try {
      // Get current row count first
      final getResponse = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId!,
        'Gastos!A:A',
      );
      
      final rowCount = getResponse.values?.length ?? 1;
      final nextRow = rowCount + 1;
      
      debugPrint('Current row count: $rowCount, will append at row: $nextRow');
      
      final valueRange = sheets.ValueRange(
        majorDimension: 'ROWS',
        values: [gasto.toSheetRow()],
      );
      
      await _sheetsApi!.spreadsheets.values.update(
        valueRange,
        _spreadsheetId!,
        'Gastos!A$nextRow',
        valueInputOption: 'USER_ENTERED',
      );
      
      debugPrint('Gasto added successfully at row $nextRow');
    } catch (e) {
      debugPrint('Error adding gasto: $e');
      rethrow;
    }
  }

  Future<List<Vencimiento>> getVencimientos() async {
    if (_sheetsApi == null || _spreadsheetId == null) {
      throw Exception('No autenticado');
    }

    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId!,
        'Vencimientos',
      );

      final vencimientos = <Vencimiento>[];
      if (response.values != null && response.values!.isNotEmpty) {
        // Skip header row
        for (int i = 1; i < response.values!.length; i++) {
          final row = response.values![i];
          if (row is List && row.isNotEmpty && row[0].toString().isNotEmpty) {
            vencimientos.add(Vencimiento.fromSheetRow(row));
          }
        }
      }

      return vencimientos;
    } catch (e) {
      debugPrint('Error getting vencimientos: $e');
      return [];
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return request.send();
  }
}
