import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/country.dart';
import '../theme/og_colors.dart';
import '../theme/og_text.dart';
import 'og_fields.dart';
import 'og_screen.dart';

/// One outlined field: flag and country code, a divider, then the number.
/// With [onCountryChanged] the country part opens a list; without it the
/// country is fixed, as for an account's own region.
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.country,
    required this.controller,
    this.onCountryChanged,
    this.onSubmitted,
    this.error,
    this.label = 'Mobile number',
  });

  final Country country;
  final ValueChanged<Country>? onCountryChanged;
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final String? error;
  final String label;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  final _menu = OverlayPortalController();
  final _link = LayerLink();

  bool get _canPick => widget.onCountryChanged != null;

  void _pick(Country c) {
    HapticFeedback.selectionClick();
    widget.onCountryChanged?.call(c);
    _menu.hide();
  }

  Widget _countryPart(OgColors c) {
    final part = Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.country.flag(),
          const SizedBox(width: 8),
          Text(
            widget.country.dialCode,
            style: OgText.input.copyWith(
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
          if (_canPick)
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: c.text),
          const SizedBox(width: 10),
          Container(width: 2, height: 28, color: c.borderControl),
        ],
      ),
    );
    if (!_canPick) {
      return Semantics(
        label:
            'Country code, ${widget.country.name} ${widget.country.dialCode}',
        child: ExcludeSemantics(child: part),
      );
    }
    return Semantics(
      button: true,
      label: 'Country code, ${widget.country.name} ${widget.country.dialCode}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          _menu.toggle();
        },
        child: ExcludeSemantics(child: part),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _menu,
            overlayChildBuilder: (_) => _dropdown(c),
            child: OgInput(
              controller: widget.controller,
              label: widget.label,
              prefix: _countryPart(c),
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              textInputAction: TextInputAction.done,
              onSubmitted: widget.onSubmitted,
              // Red outline only: the sentence goes underneath, with its icon.
              error: widget.error == null ? null : '',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
            ),
          ),
        ),
        if (widget.error != null) OgErrorText(widget.error!),
      ],
    );
  }

  Widget _dropdown(OgColors c) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _menu.hide,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          offset: const Offset(0, 64),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 270,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.borderControl, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E1C1F23),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final country in Country.values) _row(c, country),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(OgColors c, Country country) {
    final selected = country == widget.country;
    return Semantics(
      button: true,
      selected: selected,
      label: '${country.name} ${country.dialCode}',
      child: GestureDetector(
        onTap: () => _pick(country),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? c.primaryTint : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                country.flag(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    country.name,
                    style: OgText.body(
                      16,
                      weight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: c.text,
                    ),
                  ),
                ),
                Text(
                  country.dialCode,
                  style: OgText.body(16, color: c.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
