import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/env.dart';
import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/pressable.dart';
import '../../core/share.dart';
import '../clubs/domain/club_sport.dart';
import '../play/application/play_providers.dart';
import '../play/domain/activity.dart';
import '../shell/main_shell.dart';

const _muted = Color(0xFFC9C6BC);
const _glass = Color(0x24FFFFFF);

/// Scan Olympus codes (Meet check-in, players, tickets), or show my own
/// code. Always dark, like a camera view. The camera runs only while this
/// tab is on screen in Scan mode.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _camera = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _visible = false;
  bool _handling = false;
  bool _myCode = false;
  bool _torch = false;

  static final _host = RegExp.escape(Links.host);

  /// Player codes are profile links: `<host>/username`.
  static final _playerLink = RegExp('$_host/([A-Za-z0-9_]{3,30})/?\$');

  /// Meet codes at the venue: `<host>/meet/<id>`.
  static final _meetLink = RegExp('$_host/meet/([0-9a-f-]{36}|[a-z0-9-]+)/?\$');

  /// Event tickets: `olympusgo:ticket:<event id>:<booking code>`.
  static final _ticket = RegExp(r'^olympusgo:ticket:([^:]+):(.+)$');

  bool get _cameraWanted => _visible && !_myCode;

  Future<void> _syncCamera() async {
    if (_cameraWanted) {
      await _camera.start();
    } else {
      if (_torch) setState(() => _torch = false);
      await _camera.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The tab shell turns tickers off for tabs that are not showing.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    _syncCamera();
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    if (!_cameraWanted) return;
    HapticFeedback.selectionClick();
    await _camera.toggleTorch();
    setState(() => _torch = !_torch);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
    final meet = _meetLink.firstMatch(raw)?.group(1);
    final player = meet == null ? _playerLink.firstMatch(raw)?.group(1) : null;
    final ticket = _ticket.firstMatch(raw);
    final to = meet != null
        ? Routes.checkIn(meet)
        : player != null
        ? Routes.scannedPlayer(player)
        : ticket != null
        ? Routes.eventScan(ticket.group(1)!, code: ticket.group(2))
        : null;
    if (to == null) return;
    _handling = true;
    HapticFeedback.mediumImpact();
    await _camera.stop();
    if (!mounted) return;
    await context.push(to);
    _handling = false;
    if (mounted) await _syncCamera();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: OgColors.ink,
        body: Padding(
          padding: EdgeInsets.only(
            top: top,
            // The page doesn't scroll, so skip the tab bar's breathing room.
            bottom: MainTabBar.reservedHeight(context) - 16,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Scan',
                          textAlign: TextAlign.center,
                          style: OgText.display(19, color: Colors.white),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: _myCode ? 0 : 1,
                      child: Pressable(
                        semanticLabel: _torch ? 'Torch, on' : 'Torch',
                        selected: _torch,
                        onPressed: _myCode ? null : _toggleTorch,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _torch ? OgColors.lime : _glass,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: OgIcon(
                            OgIcons.torch,
                            size: 20,
                            strokeWidth: 1.9,
                            color: _torch ? OgColors.ink : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _ModeSwitch(
                  myCode: _myCode,
                  onChanged: (v) {
                    setState(() => _myCode = v);
                    _syncCamera();
                  },
                ),
              ),
              Expanded(
                child: _myCode
                    ? const _MyCode()
                    : _Scanner(camera: _camera, onDetect: _onDetect),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.myCode, required this.onChanged});

  final bool myCode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget mode(String label, bool on, bool value) => Expanded(
      child: Pressable(
        semanticLabel: label,
        selected: on,
        onPressed: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: OgText.body(
              14,
              weight: on ? FontWeight.w700 : FontWeight.w600,
              color: on ? OgColors.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _glass,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          mode('Scan', !myCode, false),
          const SizedBox(width: 4),
          mode('My code', myCode, true),
        ],
      ),
    );
  }
}

class _Scanner extends StatelessWidget {
  const _Scanner({required this.camera, required this.onDetect});

  final MobileScannerController camera;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    // In demo mode the rows open sample results; with a backend they explain
    // what the camera can read.
    final demo = !Env.hasSupabase;
    final uses = [
      (
        'Check in to a Meet',
        'Scan the organizer’s code at the court',
        Routes.checkIn('ts-social'),
      ),
      (
        'Use points at a partner shop',
        'Scan at the counter to take S\$ off',
        Routes.points,
      ),
      (
        'Add a player',
        'Scan their code to follow or message them',
        Routes.scannedPlayer('hannahgoh'),
      ),
      (
        'Check a ticket',
        'Organizers scan tickets at the door',
        Routes.checkTickets,
      ),
    ];
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            // The frame is 240pt, smaller on short screens so the rows fit.
            builder: (context, box) {
              final frame = (box.maxHeight - (demo ? 112 : 88)).clamp(
                120.0,
                240.0,
              );
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: frame,
                      height: frame,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: MobileScanner(
                                controller: camera,
                                onDetect: onDetect,
                                errorBuilder: (_, _) => const SizedBox.shrink(),
                                placeholderBuilder: (_) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          const Positioned.fill(child: _Viewfinder()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Point at an Olympus QR code',
                      style: OgText.body(
                        15,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (demo) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Demo: tap a row below to see a result',
                        style: OgText.body(13, color: _muted),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var i = 0; i < uses.length; i++)
                Pressable(
                  semanticLabel: '${uses[i].$1}. ${uses[i].$2}',
                  onPressed: demo ? () => context.push(uses[i].$3) : null,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: i < uses.length - 1
                          ? const Border(
                              bottom: BorderSide(color: Color(0x1AFFFFFF)),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2C14E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: OgText.body(
                              12,
                              weight: FontWeight.w800,
                              color: const Color(0xFF3A2C00),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                uses[i].$1,
                                style: OgText.body(
                                  14,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                uses[i].$2,
                                style: OgText.body(12, color: _muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyCode extends ConsumerWidget {
  const _MyCode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(sessionProfileProvider).value;
    final sport = ref.watch(mySportsProvider).value?.firstOrNull;
    final tickets = (ref.watch(myScheduleProvider).value ?? const [])
        .where((a) => a.kind == ActivityKind.event && !a.iAmHost)
        .length;
    final username = profile?.username ?? '';
    final level = sport == null
        ? null
        : '${SkillBand.forLevel(sport.level).code} ${sport.level.toStringAsFixed(1)}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Semantics(
                  label: 'Your QR code',
                  image: true,
                  child: QrImageView(
                    data: Links.player(username),
                    size: 208,
                    padding: EdgeInsets.zero,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: OgColors.ink,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: OgColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  profile?.fullName ?? username,
                  style: OgText.heading(19, color: OgColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  ['@$username', ?level].join(' · '),
                  style: OgText.body(13, color: const Color(0xFF5B6168)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Show this at an event door, to an organizer adding a walk-in, '
              'or to a player who wants to add you.',
              textAlign: TextAlign.center,
              style: OgText.body(14, height: 1.45, color: _muted),
            ),
          ),
          const SizedBox(height: 16),
          Pressable(
            semanticLabel: 'My tickets, $tickets',
            onPressed: () => context.push(Routes.myTickets),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x99FFFFFF), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'My tickets · $tickets',
                    style: OgText.body(
                      15,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: OgColors.tangerine, width: 4);
    const r = Radius.circular(16);
    Widget corner(Alignment a, Border border, BorderRadius radius) => Align(
      alignment: a,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(border: border, borderRadius: radius),
      ),
    );
    return Semantics(
      label: 'Camera viewfinder',
      child: Stack(
        children: [
          corner(
            Alignment.topLeft,
            const Border(left: side, top: side),
            const BorderRadius.only(topLeft: r),
          ),
          corner(
            Alignment.topRight,
            const Border(right: side, top: side),
            const BorderRadius.only(topRight: r),
          ),
          corner(
            Alignment.bottomLeft,
            const Border(left: side, bottom: side),
            const BorderRadius.only(bottomLeft: r),
          ),
          corner(
            Alignment.bottomRight,
            const Border(right: side, bottom: side),
            const BorderRadius.only(bottomRight: r),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 2,
                color: OgColors.tangerine.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
