import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geohash.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/presentation/play_card.dart';
import '../application/discover_providers.dart';
import '../domain/discover_models.dart';

const _distances = <double>[2, 5, 10, 25];
const _times = [('Morning', 6, 12), ('Afternoon', 12, 18), ('Evening', 18, 24)];

/// Find a Meet: a two-week date strip, filters, and a list or a map.
class FindScreen extends ConsumerStatefulWidget {
  const FindScreen({super.key});

  @override
  ConsumerState<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends ConsumerState<FindScreen> {
  DiscoverFilter _filter = const DiscoverFilter();
  bool _map = false;
  bool _sharing = false;
  bool _busy = false;

  void _set(DiscoverFilter f) => setState(() => _filter = f);

  /// Asks first, then sends only a coarse area.
  Future<void> _useMyArea() async {
    if (_sharing) {
      await ref.read(discoverRepositoryProvider).stopSharingArea();
      ref.invalidate(foundSessionsProvider);
      setState(() => _sharing = false);
      return;
    }
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Use your area?'),
        content: const Text(
          'We keep only a rough area, about 5 km across, to sort Meets near '
          'you. Other players never see it. You can turn this off at any time.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use my area'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          showOgToast(
            context,
            'Location is off. You can still search by date and sport.',
            error: true,
          );
        }
        return;
      }
      final here = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      await ref
          .read(discoverRepositoryProvider)
          .shareArea(geohash(here.latitude, here.longitude));
      ref.invalidate(foundSessionsProvider);
      setState(() => _sharing = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } on Exception {
      if (mounted) {
        showOgToast(context, "Couldn't find your area.", error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final found = ref.watch(foundSessionsProvider(_filter));
    return KitScaffold(
      header: const KitHeader(title: 'Find a Meet'),
      gap: 12,
      children: [
        _DateStrip(
          selected: _filter.day,
          onPicked: (d) => _set(_filter.copyWith(day: d)),
        ),
        _Chips(
          children: [
            for (final s in const [Sport.badminton, Sport.pickleball])
              KitChip(
                label: s.label,
                selected: _filter.sport == s,
                onTap: () => _set(
                  _filter.copyWith(sport: _filter.sport == s ? null : s),
                ),
              ),
            for (final (label, from, to) in _times)
              KitChip(
                label: label,
                selected: _filter.hourFrom == from,
                onTap: () => _set(
                  _filter.hourFrom == from
                      ? _filter.copyWith(hourFrom: null, hourTo: null)
                      : _filter.copyWith(hourFrom: from, hourTo: to),
                ),
              ),
          ],
        ),
        _Chips(
          children: [
            KitChip(
              label: _busy
                  ? 'Finding your area'
                  : _sharing
                  ? 'Using my area'
                  : 'Use my area',
              selected: _sharing,
              onTap: _busy ? null : _useMyArea,
            ),
            if (_sharing)
              for (final km in _distances)
                KitChip(
                  label: 'Within ${km.toInt()} km',
                  selected: _filter.maxKm == km,
                  onTap: () => _set(
                    _filter.copyWith(maxKm: _filter.maxKm == km ? null : km),
                  ),
                ),
          ],
        ),
        KitSegments(
          labels: const ['List', 'Map'],
          selected: _map ? 1 : 0,
          onSelect: (i) => setState(() => _map = i == 1),
        ),
        ...found.when(
          loading: () => const [Center(child: CupertinoActivityIndicator())],
          error: (e, _) => [
            KitNote(
              e is AuthFailure ? e.message : 'Something went wrong. Try again.',
              tone: KitTone.warn,
            ),
          ],
          data: (list) {
            if (list.isEmpty) {
              return [
                DashedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No Meets match. Try another day, or clear a filter.',
                      style: OgText.lead(c.textMuted),
                    ),
                  ),
                ),
              ];
            }
            if (_map) return [_MeetMap(found: list)];
            return [
              for (final s in list)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.km != null || s.fitsMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          [
                            if (s.km != null)
                              '${s.km!.toStringAsFixed(1)} km away',
                            if (s.fitsMe) 'Fits your level',
                          ].join(' · '),
                          style: OgText.body(13, color: c.textMuted),
                        ),
                      ),
                    PlayCard(activity: s.activity),
                  ],
                ),
            ];
          },
        ),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(spacing: 8, children: children),
  );
}

/// Today and the next 13 days. Tapping the selected day clears it.
class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selected, required this.onPicked});

  final DateTime? selected;
  final ValueChanged<DateTime?> onPicked;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        spacing: 6,
        children: [
          for (var i = 0; i < 14; i++)
            Builder(
              builder: (context) {
                final day = DateTime(today.year, today.month, today.day + i);
                final on = selected == day;
                return Pressable(
                  semanticLabel: '${_names[day.weekday - 1]} ${day.day}',
                  selected: on,
                  onPressed: () => onPicked(on ? null : day),
                  child: Container(
                    width: 48,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? c.primarySmall : c.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _names[day.weekday - 1],
                          style: OgText.body(
                            12,
                            color: on ? c.onPrimary : c.textMuted,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: OgText.body(
                            16,
                            weight: FontWeight.w600,
                            color: on ? c.onPrimary : c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Meets on OpenStreetMap, at their venues. Other players are never on it.
class _MeetMap extends StatelessWidget {
  const _MeetMap({required this.found});

  final List<FoundSession> found;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final placed = found.where((s) => s.latitude != null).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 420,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(1.3521, 103.8198),
            initialZoom: 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.olympusgo.olympusGo',
            ),
            MarkerLayer(
              markers: [
                for (final s in placed)
                  Marker(
                    point: LatLng(s.latitude!, s.longitude!),
                    width: 44,
                    height: 44,
                    child: Pressable(
                      semanticLabel: s.activity.title,
                      onPressed: () =>
                          context.push(Routes.activity(s.activity.id)),
                      child: OgIcon(
                        OgIcons.mapPin,
                        size: 32,
                        color: c.primarySmall,
                      ),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
      ),
    );
  }
}
