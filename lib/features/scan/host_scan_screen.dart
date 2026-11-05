import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/widgets/og_kit.dart';
import '../auth/data/auth_repository.dart';

/// The host scans each player's QR at the door. The camera stays open, so a
/// queue can go through one after another.
class HostScanScreen extends ConsumerStatefulWidget {
  const HostScanScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<HostScanScreen> createState() => _HostScanScreenState();
}

class _HostScanScreenState extends ConsumerState<HostScanScreen> {
  static final _token = RegExp(r'^olympusgo:player:([0-9a-z]{16,64})$');

  final _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  String? _last;
  int _present = 0;
  bool _problem = false;
  bool _busy = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
    final token = _token.firstMatch(raw)?.group(1);
    if (token == null) return;
    _busy = true;
    try {
      final (name, present) = await ref
          .read(playRepositoryProvider)
          .hostCheckIn(widget.activityId, token);
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          _last = '$name is Present';
          _present = present;
          _problem = false;
        });
      }
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _last = e.message;
          _problem = true;
        });
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return KitScaffold(
      header: const KitHeader(title: 'Scan players'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 320,
            child: MobileScanner(controller: _camera, onDetect: _onDetect),
          ),
        ),
        if (_last != null)
          KitNote(_last!, tone: _problem ? KitTone.warn : KitTone.success),
        Text(
          '$_present here so far. Point the camera at a player\'s My QR.',
          style: OgText.body(15, color: c.textMuted),
        ),
      ],
    );
  }
}
