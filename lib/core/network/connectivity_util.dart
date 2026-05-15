import 'package:connectivity_plus/connectivity_plus.dart';

/// Best-effort: no path to the internet is proven, only that a transport exists.
/// Never block login indefinitely — the platform channel can stall on some devices.
Future<bool> deviceHasUsableNetwork() async {
  try {
    final results = await Connectivity()
        .checkConnectivity()
        .timeout(const Duration(seconds: 2), onTimeout: () => <ConnectivityResult>[]);
    if (results.isEmpty) return true;
    return results.any((r) => r != ConnectivityResult.none);
  } catch (_) {
    return true;
  }
}
