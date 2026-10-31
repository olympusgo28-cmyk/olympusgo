import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../theme/og_text.dart';
import 'og_kit.dart';
import 'og_toast.dart';

/// A group's, venue's or vendor's code, with a way to replace it. Anyone holding
/// an old code gets "That code isn't valid."
Future<void> showPlaceCode(
  BuildContext context, {
  required String title,
  required Future<String> Function(bool rotate) load,
}) => showKitSheet<void>(
  context,
  builder: (_) => _PlaceCode(title: title, load: load),
);

class _PlaceCode extends StatefulWidget {
  const _PlaceCode({required this.title, required this.load});

  final String title;
  final Future<String> Function(bool rotate) load;

  @override
  State<_PlaceCode> createState() => _PlaceCodeState();
}

class _PlaceCodeState extends State<_PlaceCode> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetch(false);
  }

  Future<void> _fetch(bool rotate) async {
    try {
      final token = await widget.load(rotate);
      if (mounted) setState(() => _token = token);
    } on AuthFailure catch (e) {
      if (mounted) {
        showOgToast(context, e.message, error: true);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.title, style: OgText.heading(24)),
      const SizedBox(height: 16),
      if (_token == null)
        const CupertinoActivityIndicator()
      else
        Center(
          child: Semantics(
            label: 'Code for ${widget.title}',
            image: true,
            child: QrImageView(data: 'olympusgo:place:$_token', size: 220),
          ),
        ),
      const SizedBox(height: 16),
      KitButton.outline(
        label: 'Replace this code',
        onPressed: _token == null ? null : () => _fetch(true),
      ),
    ],
  );
}
