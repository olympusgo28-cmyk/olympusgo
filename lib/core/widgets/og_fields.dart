import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/og_colors.dart';
import '../theme/og_text.dart';

InputDecoration _decoration(
  BuildContext context, {
  String? hint,
  String? error,
  bool valid = false,
}) {
  final c = context.og;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: OgText.input.copyWith(color: c.textMuted),
    filled: true,
    fillColor: c.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    enabledBorder: border(valid ? c.success : c.borderControl, 2),
    focusedBorder: border(valid ? c.success : c.primary, 3),
    errorBorder: border(c.error, 2),
    focusedErrorBorder: border(c.error, 3),
    errorText: error,
    errorStyle: OgText.body(14, weight: FontWeight.w600, color: c.error),
  );
}

/// Labelled 56px text field from the design.
class OgTextField extends StatelessWidget {
  const OgTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.hint,
    this.error,
    this.autofocus = false,
    this.autocorrect = true,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
    this.valid = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? error;
  final bool autofocus;
  final bool autocorrect;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;

  /// Draws a green border, as when a username is free.
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: OgText.label),
        const SizedBox(height: 8),
        OgInput(
          controller: controller,
          semanticLabel: label,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          hint: hint,
          error: error,
          autofocus: autofocus,
          autocorrect: autocorrect,
          capitalization: capitalization,
          inputFormatters: inputFormatters,
          valid: valid,
        ),
      ],
    );
  }
}

/// The bare bordered input, for rows that lay out their own labels.
class OgInput extends StatelessWidget {
  const OgInput({
    super.key,
    required this.controller,
    this.semanticLabel,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.hint,
    this.error,
    this.autofocus = false,
    this.autocorrect = true,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
    this.valid = false,
  });

  final TextEditingController controller;
  final String? semanticLabel;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? error;
  final bool autofocus;
  final bool autocorrect;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        autofocus: autofocus,
        autocorrect: autocorrect,
        enableSuggestions: autocorrect,
        textCapitalization: capitalization,
        inputFormatters: inputFormatters,
        style: OgText.input.copyWith(color: context.og.text),
        decoration: _decoration(
          context,
          hint: hint,
          error: error,
          valid: valid,
        ),
      ),
    );
  }
}

/// A field-looking button that opens a picker (country, month, level).
class OgSelectField extends StatelessWidget {
  const OgSelectField({
    super.key,
    required this.value,
    required this.onTap,
    this.semanticLabel,
    this.leading,
    this.bold = false,
    this.chevron = true,
    this.placeholder = false,
    this.height = 56,
    this.fontSize = 18,
  });

  final double height;
  final double fontSize;

  /// False for compact fields (day, year) where the chevron would crowd the value.
  final bool chevron;

  /// Shows [value] in the muted colour, as a hint.
  final bool placeholder;
  final String value;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Widget? leading;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      button: true,
      label: semanticLabel,
      value: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderControl, width: 2),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(
                      fontSize,
                      weight: bold ? FontWeight.w600 : FontWeight.w400,
                      color: placeholder ? c.textMuted : c.text,
                    ),
                  ),
                ),
                if (chevron)
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: c.text,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Six-box verification code. One hidden field drives the boxes so iOS can
/// offer the code from Messages or Mail above the keyboard.
class OgCodeInput extends StatefulWidget {
  const OgCodeInput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.hasError = false,
    this.length = 6,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final int length;

  @override
  State<OgCodeInput> createState() => _OgCodeInputState();
}

class _OgCodeInputState extends State<OgCodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _changed() {
    setState(() {});
    final v = widget.controller.text;
    if (v.length == widget.length) widget.onCompleted?.call(v);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final text = widget.controller.text;
    return Semantics(
      label: '${widget.length}-digit code',
      value: text,
      textField: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focus.requestFocus,
        child: Stack(
          children: [
            // Off-screen field that owns the keyboard and autofill.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _box(c, i, text),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(OgColors c, int i, String text) {
    final active =
        _focus.hasFocus &&
        (i == text.length ||
            (text.length == widget.length && i == widget.length - 1));
    final borderColor = widget.hasError
        ? c.error
        : active
        ? c.primary
        : c.borderControl;
    return Container(
      width: 48,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: active ? 3 : 2),
      ),
      child: Text(
        i < text.length ? text[i] : '',
        style: OgText.body(26, weight: FontWeight.w600, color: c.text),
      ),
    );
  }
}
