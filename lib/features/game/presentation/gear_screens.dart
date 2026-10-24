import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../wallet/presentation/wallet_screens.dart' show cash;
import '../application/game_providers.dart';
import '../domain/game_models.dart';

String _icon(GearType t) => switch (t) {
  GearType.shoes => OgIcons.bag,
  GearType.pickleballPaddle => OgIcons.sportPickleball,
  GearType.tableTennisBat => OgIcons.sportTableTennis,
  GearType.tennisRacquet => OgIcons.sportTennis,
  GearType.badmintonRacquet => OgIcons.racquet,
};

/// What the player plays with.
class MyGearScreen extends ConsumerWidget {
  const MyGearScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final gear = ref.watch(myGearProvider).value;
    return KitScaffold(
      header: const KitHeader(title: 'My gear'),
      bottom: [
        KitButton(
          label: 'Add gear',
          icon: OgIcons.plus,
          onPressed: () => context.push(Routes.gearEdit('new')),
        ),
      ],
      children: [
        Text(
          'Others can see it on your player profile.',
          style: OgText.body(14, color: c.textMuted),
        ),
        if (gear == null)
          const CupertinoActivityIndicator()
        else if (gear.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Add your racquet, shoes and strings to track restrings and wear.',
                style: OgText.body(14, color: c.textMuted),
              ),
            ),
          )
        else
          KitCard(
            children: [
              for (final g in gear)
                KitNavTile(
                  icon: _icon(g.type),
                  title: g.name,
                  subtitle: [
                    g.type.label,
                    ...g.specs.take(2).map((s) => s.$2),
                  ].join(' · '),
                  onTap: () => context.push(Routes.gearItem(g.id)),
                ),
            ],
          ),
      ],
    );
  }
}

/// One item: its specs and string setup.
class GearItemScreen extends ConsumerWidget {
  const GearItemScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tones;
    final g = ref
        .watch(myGearProvider)
        .value
        ?.where((g) => g.id == id)
        .firstOrNull;
    if (g == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Gear'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final strings = g.specs
        .where(
          (s) => const [
            'String',
            'Vertical (mains)',
            'Horizontal (crosses)',
            'Knots',
          ].contains(s.$1),
        )
        .toList();
    final rest = g.specs.where((s) => !strings.contains(s)).toList();
    return KitScaffold(
      header: KitHeader(title: g.type.label, crumb: g.name),
      bottom: [
        KitButton(
          label: 'Find it in the Shop',
          onPressed: () => context.push(Routes.shop),
        ),
        KitButton(
          label: 'Edit gear details',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.gearEdit(g.id)),
        ),
      ],
      children: [
        Container(
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.tag,
            borderRadius: BorderRadius.circular(22),
          ),
          child: OgIcon(_icon(g.type), size: 72, color: t.onTag),
        ),
        Text(g.name, style: OgText.heading(26)),
        if (g.priceCents != null)
          Text(cash(g.priceCents!), style: OgText.heading(20)),
        Column(children: [for (final (k, v) in rest) KitKeyValue(k, v)]),
        if (strings.isNotEmpty) ...[
          Text('String setup', style: OgText.heading(20)),
          Column(children: [for (final (k, v) in strings) KitKeyValue(k, v)]),
        ],
      ],
    );
  }
}

/// Add gear, or edit it: type, brand, model, then type-specific fields.
class GearEditScreen extends ConsumerStatefulWidget {
  const GearEditScreen({super.key, required this.id});

  /// "new" for new gear.
  final String id;

  @override
  ConsumerState<GearEditScreen> createState() => _GearEditScreenState();
}

class _GearEditScreenState extends ConsumerState<GearEditScreen> {
  GearType _type = GearType.badmintonRacquet;
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _string = TextEditingController();
  final _mains = TextEditingController(text: '26');
  final _crosses = TextEditingController(text: '24');
  String _knots = '4 knots';
  String _size = 'UK 8';
  String _fit = 'Regular';
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_brand, _model, _string, _mains, _crosses]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Gear g) {
    _loaded = true;
    _type = g.type;
    _brand.text = g.brand;
    _model.text = g.model;
    String? spec(String k) => g.specs.where((s) => s.$1 == k).firstOrNull?.$2;
    _string.text = spec('String') ?? '';
    _mains.text = (spec('Vertical (mains)') ?? '26').replaceAll(' lbs', '');
    _crosses.text = (spec('Horizontal (crosses)') ?? '24').replaceAll(
      ' lbs',
      '',
    );
    _knots = spec('Knots') ?? _knots;
    _size = spec('Size') ?? _size;
    _fit = spec('Fit') ?? _fit;
  }

  Future<void> _save(Gear? before) async {
    if (_brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      showOgToast(context, 'Add the brand and model.', error: true);
      return;
    }
    final kept =
        before?.specs.where(
          (s) => !const [
            'String',
            'Vertical (mains)',
            'Horizontal (crosses)',
            'Knots',
            'Size',
            'Fit',
          ].contains(s.$1),
        ) ??
        const [];
    setState(() => _busy = true);
    try {
      await ref
          .read(gameRepositoryProvider)
          .saveGear(
            Gear(
              id: before?.id ?? '',
              type: _type,
              brand: _brand.text.trim(),
              model: _model.text.trim(),
              priceCents: before?.priceCents,
              specs: [
                ...kept,
                if (_type.strung) ...[
                  if (_string.text.trim().isNotEmpty)
                    ('String', _string.text.trim()),
                  ('Vertical (mains)', '${_mains.text.trim()} lbs'),
                  ('Horizontal (crosses)', '${_crosses.text.trim()} lbs'),
                  ('Knots', _knots),
                ],
                if (_type == GearType.shoes) ...[
                  ('Size', _size),
                  ('Fit', _fit),
                ],
              ],
            ),
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(myGearProvider);
      if (mounted) context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final before = widget.id == 'new'
        ? null
        : ref
              .watch(myGearProvider)
              .value
              ?.where((g) => g.id == widget.id)
              .firstOrNull;
    if (before != null && !_loaded) _load(before);
    return KitScaffold(
      header: KitHeader(title: before == null ? 'Add gear' : 'Edit gear'),
      bottom: [
        KitButton(
          label: 'Save gear',
          loading: _busy,
          onPressed: () => _save(before),
        ),
      ],
      children: [
        Text(
          'Add what you play with. Others can see it on your player profile.',
          style: OgText.body(14, color: context.og.textMuted),
        ),
        Text('Gear type', style: OgText.body(15, weight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in GearType.values)
              KitChip(
                label: t.label,
                selected: _type == t,
                onTap: () => setState(() => _type = t),
              ),
          ],
        ),
        KitInput(label: 'Brand', controller: _brand, hint: 'Yonex'),
        KitInput(label: 'Model', controller: _model, hint: 'Astrox 99 Pro'),
        if (_type.strung) ...[
          Text('String setup', style: OgText.heading(20)),
          Text(
            'Strings and tension for your racquet.',
            style: OgText.body(13, color: context.og.textMuted),
          ),
          KitInput(
            label: 'String',
            controller: _string,
            hint: 'Yonex BG65 Titanium',
          ),
          Row(
            children: [
              Expanded(
                child: KitInput(
                  label: 'Vertical (mains), lbs',
                  controller: _mains,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KitInput(
                  label: 'Horizontal (crosses), lbs',
                  controller: _crosses,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          KitSegments(
            labels: const ['2 knots', '4 knots'],
            selected: _knots == '2 knots' ? 0 : 1,
            onSelect: (i) =>
                setState(() => _knots = i == 0 ? '2 knots' : '4 knots'),
          ),
        ],
        if (_type == GearType.shoes) ...[
          Text('Size', style: OgText.body(15, weight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in const ['UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10'])
                KitChip(
                  label: s,
                  selected: _size == s,
                  onTap: () => setState(() => _size = s),
                ),
            ],
          ),
          Text('Fit', style: OgText.body(15, weight: FontWeight.w700)),
          KitSegments(
            labels: const ['Narrow', 'Regular', 'Wide'],
            selected: const ['Narrow', 'Regular', 'Wide'].indexOf(_fit),
            onSelect: (i) =>
                setState(() => _fit = const ['Narrow', 'Regular', 'Wide'][i]),
          ),
        ],
      ],
    );
  }
}
