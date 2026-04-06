import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.com.fletar.fletar_app';
  static const String androidWidgetName = 'HomeWidgetExampleProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> updateTotal(double total, String spreadsheetId) async {
    await HomeWidget.saveWidgetData('total_month', '\$${total.toStringAsFixed(2)}');
    await HomeWidget.saveWidgetData('spreadsheet_id', spreadsheetId);
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
    );
  }

  static Future<void> updateGastos(List<Map<String, dynamic>> gastos) async {
    final gastoStrings = gastos.map((g) => 
      '${g['detalle']}: \$${g['precio']}'
    ).take(5).toList();
    
    await HomeWidget.saveWidgetData('recent_gastos', gastoStrings.join('\n'));
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
    );
  }
}
