import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';
import 'package:og_money/og_money.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// Partner shops and their products. Content staff only: the database checks
/// the role and MFA on every call.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  late Future<List<dynamic>> _shops = _load();
  Map<String, dynamic>? _open;

  Future<List<dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_shop_list') as List<dynamic>;

  void _refresh() => setState(() {
    _shops = _load();
  });

  Future<void> _save([Map<String, dynamic>? shop]) async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ShopForm(shop: shop),
    );
    if (saved == null || !mounted) return;
    final reason = await askReason(context, 'Save this shop');
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_shop_save', {
        'p': saved,
        'p_reason': reason,
      });
      _refresh();
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    if (open != null) {
      return _ProductsPage(
        shop: open,
        onBack: () => setState(() => _open = null),
      );
    }
    return StaffPage(
      title: 'Catalogue',
      actions: [
        FilledButton(onPressed: _save, child: const Text('Add a shop')),
      ],
      child: Loaded<List<dynamic>>(
        future: _shops,
        isEmpty: (r) => r.isEmpty,
        emptyText: 'No shops yet.',
        builder: (shops) => ListView(
          children: [
            for (final s in shops.cast<Map<String, dynamic>>())
              ListTile(
                title: Text('${s['name']}'),
                subtitle: Text(
                  [
                    s['active'] == true ? 'Open' : 'Closed',
                    '${s['products']} products',
                    s['owner'] == null ? 'No owner yet' : 'Owner ${s['owner']}',
                  ].join(' · '),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _save(s),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _open = s),
                      child: const Text('Products'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopForm extends StatefulWidget {
  const _ShopForm({this.shop});
  final Map<String, dynamic>? shop;

  @override
  State<_ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<_ShopForm> {
  late final _name = TextEditingController(
    text: widget.shop?['name'] as String?,
  );
  late final _blurb = TextEditingController(
    text: widget.shop?['blurb'] as String?,
  );
  late final _address = TextEditingController(
    text: widget.shop?['collect_address'] as String?,
  );
  late bool _active = widget.shop?['active'] == true;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.shop == null ? 'Add a shop' : 'Edit this shop'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _blurb,
            decoration: const InputDecoration(labelText: 'One line about it'),
          ),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Collection address'),
          ),
          SwitchListTile(
            title: const Text('Open'),
            subtitle: const Text('Needs an owner and a collection address'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_name.text.trim().isEmpty) return;
          Navigator.of(context).pop({
            'id': ?widget.shop?['id'],
            'name': _name.text.trim(),
            'blurb': _blurb.text.trim(),
            'collect_address': _address.text.trim(),
            'active': _active,
          });
        },
        child: const Text('Next'),
      ),
    ],
  );
}

class _ProductsPage extends ConsumerStatefulWidget {
  const _ProductsPage({required this.shop, required this.onBack});
  final Map<String, dynamic> shop;
  final VoidCallback onBack;

  @override
  ConsumerState<_ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<_ProductsPage> {
  late Future<List<dynamic>> _rows = _load();

  Future<List<dynamic>> _load() async => await ref.read(staffApiProvider).read(
    'staff_product_list',
    {'p_mall': widget.shop['id']},
  ) as List<dynamic>;

  void _refresh() => setState(() {
    _rows = _load();
  });

  Future<void> _act(
    String title,
    String action,
    Map<String, dynamic> params,
  ) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act(action, {
        ...params,
        'p_reason': reason,
      });
      _refresh();
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _save([Map<String, dynamic>? product]) async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProductForm(product: product),
    );
    if (saved == null || !mounted) return;
    await _act('Save this product', 'staff_product_save', {
      'p': {...saved, 'mall_id': widget.shop['id']},
    });
  }

  Future<void> _stock(Map<String, dynamic> product) async {
    final amount = TextEditingController();
    final change = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change stock'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: amount,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Add or take away',
              helperText:
                  '5 adds five, -2 takes two away. Items held for someone '
                  'paying are safe.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(amount.text.trim());
              if (n != null && n != 0) Navigator.of(context).pop(n);
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
    if (change == null || !mounted) return;
    await _act('Change stock', 'staff_product_stock', {
      'p_product': product['id'],
      'p_change': change,
    });
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: '${widget.shop['name']}',
    actions: [
      TextButton(onPressed: widget.onBack, child: const Text('All shops')),
      const SizedBox(width: 8),
      FilledButton(onPressed: _save, child: const Text('Add a product')),
    ],
    child: Loaded<List<dynamic>>(
      future: _rows,
      isEmpty: (r) => r.isEmpty,
      emptyText: 'No products yet.',
      builder: (rows) => ListView(
        children: [
          for (final p in rows.cast<Map<String, dynamic>>())
            ListTile(
              title: Text('${p['name']}'),
              subtitle: Text(
                [
                  '${Money((p['price_cents'] as num).toInt())}',
                  if (p['service'] == true) 'Service' else '${p['stock']} left',
                  if (p['published'] != true) 'Draft',
                  if (p['hidden'] == true) 'Hidden by moderation',
                ].join(' · '),
                style: OgText.body(14, color: context.og.textMuted),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  if (p['service'] != true)
                    TextButton(
                      onPressed: () => _stock(p),
                      child: const Text('Stock'),
                    ),
                  TextButton(
                    onPressed: () => _save(p),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({this.product});
  final Map<String, dynamic>? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final _name = TextEditingController(
    text: widget.product?['name'] as String?,
  );
  late final _about = TextEditingController(
    text: widget.product?['description'] as String?,
  );
  late final _price = TextEditingController(
    text: switch (widget.product?['price_cents']) {
      final num cents => Money(cents.toInt()).decimal,
      _ => '',
    },
  );
  late bool _service = widget.product?['service'] == true;
  late bool _published = widget.product?['published'] == true;
  String? _error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.product == null ? 'Add a product' : 'Edit this product'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _about,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'About it'),
          ),
          TextField(
            controller: _price,
            decoration: InputDecoration(
              labelText: 'Shop’s price in S\$',
              errorText: _error,
            ),
          ),
          if (widget.product == null)
            SwitchListTile(
              title: const Text('A service, booked by time'),
              value: _service,
              onChanged: (v) => setState(() => _service = v),
            ),
          SwitchListTile(
            title: const Text('Show it in the Shop'),
            value: _published,
            onChanged: (v) => setState(() => _published = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final price = parseMinor(_price.text);
          if (_name.text.trim().isEmpty) return;
          if (price == null || price <= 0) {
            setState(() => _error = 'Enter an amount, like 24.50');
            return;
          }
          Navigator.of(context).pop({
            'id': ?widget.product?['id'],
            'name': _name.text.trim(),
            'description': _about.text.trim(),
            'price_cents': price,
            'service': _service,
            'published': _published,
          });
        },
        child: const Text('Next'),
      ),
    ],
  );
}
