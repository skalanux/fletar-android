import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/sheets_service.dart';
import '../models/gasto.dart';

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: const [
      'https://www.googleapis.com/auth/spreadsheets',
    ],
  );
});

final sheetsServiceProvider = Provider<SheetsService>((ref) {
  return SheetsService();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<bool> {
  final Ref ref;

  AuthNotifier(this.ref) : super(false);

  Future<void> init() async {
    final gs = ref.read(sheetsServiceProvider);
    final gsi = ref.read(googleSignInProvider);
    await gs.init(gsi);
    
    // Auto sign-in if URL is already saved
    if (gs.spreadsheetUrl != null && gs.spreadsheetUrl!.isNotEmpty) {
      await signInSilently();
    }
  }

  Future<void> signIn() async {
    final gs = ref.read(sheetsServiceProvider);
    await gs.signIn();
    state = gs.isAuthenticated;
  }

  Future<void> signInSilently() async {
    try {
      final gs = ref.read(sheetsServiceProvider);
      final gsi = ref.read(googleSignInProvider);
      
      // Try silent sign in
      final user = await gsi.signInSilently();
      if (user != null) {
        final auth = await user.authHeaders;
        await gs.setAuthenticatedClient(auth);
        state = gs.isAuthenticated;
      }
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    final gsi = ref.read(googleSignInProvider);
    await gsi.signOut();
    state = false;
  }
}

final spreadsheetUrlProvider = Provider<String?>((ref) {
  final gs = ref.read(sheetsServiceProvider);
  return gs.spreadsheetUrl;
});

final configProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  final gs = ref.read(sheetsServiceProvider);
  return gs.getConfig();
});

final gastosProvider = FutureProvider.family<List<Gasto>, int>((ref, monthOffset) async {
  final gs = ref.read(sheetsServiceProvider);
  return gs.getGastos(monthOffset: monthOffset);
});

final vencimientosProvider = FutureProvider<List<Vencimiento>>((ref) async {
  final gs = ref.read(sheetsServiceProvider);
  return gs.getVencimientos();
});

final currentMonthProvider = StateProvider<int>((ref) => 0);

final totalGastosProvider = Provider.family<double, List<Gasto>>((ref, gastos) {
  return gastos.fold(0.0, (sum, g) => sum + g.precio);
});

final gastosPorCategoriaProvider = Provider.family<Map<String, double>, List<Gasto>>((ref, gastos) {
  final map = <String, double>{};
  for (final g in gastos) {
    map[g.categoria] = (map[g.categoria] ?? 0) + g.precio;
  }
  return map;
});
