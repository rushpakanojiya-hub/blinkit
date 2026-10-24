import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Har 8 second mein GET /orders/:id/tracking se rider ki location laata hai.
/// [fetch] decoded JSON map return kare, jaise {"tracking": {...}}.
/// Pichla request khatam hone tak naya nahi chalta, aur lagatar 5 baar fail
/// hone par polling band ho jaati hai (offline hone par bekaar requests nahi).
Stream<LatLng> pollPartner(Future<Map<String, dynamic>> Function() fetch) {
  late StreamController<LatLng> ctl;
  Timer? t;
  var busy = false;
  var failures = 0;
  Future<void> tick() async {
    if (busy || ctl.isClosed) return;
    busy = true;
    try {
      final tracking = (await fetch())['tracking'];
      failures = 0;
      if (tracking is Map &&
          tracking['current_lat'] != null &&
          tracking['current_lng'] != null &&
          !ctl.isClosed) {
        ctl.add(LatLng(
          (tracking['current_lat'] as num).toDouble(),
          (tracking['current_lng'] as num).toDouble(),
        ));
      }
    } catch (_) {
      failures++;
      if (failures >= 5) t?.cancel();
    } finally {
      busy = false;
    }
  }

  ctl = StreamController<LatLng>(
    onListen: () {
      tick();
      t = Timer.periodic(const Duration(seconds: 8), (_) => tick());
    },
    onCancel: () => t?.cancel(),
  );
  return ctl.stream;
}