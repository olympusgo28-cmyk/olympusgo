import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/og_colors.dart';
import '../../core/theme/og_type.dart';

/// The outlined field style (Q251): a 2px outline, and a label that rests
/// inside it and floats into the border while typing or once filled.
InputDecoration ogOutlinedDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  String? error,
  bool valid = false,
  Widget? prefix,
  Widget? suffix,
}) {
  final c = context.og;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: context.type.secondary,
    floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
      final color = states.contains(WidgetState.error)
          ? c.error
          : valid
          ? c.success
          : states.contains(WidgetState.focused)
          ? c.link
          : c.textMuted;
      return context.type.caption.copyWith(color: color);
    }),
    hintText: hint,
    hintStyle: context.type.tertiary,
    filled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    prefixIcon: prefix,
    prefixIconConstraints: const BoxConstraints(minHeight: 48),
    suffixIcon: suffix,
    border: border(c.borderControl, 2),
    enabledBorder: border(valid ? c.success : c.borderControl, 2),
    focusedBorder: border(valid ? c.success : c.primary, 3),
    disabledBorder: border(c.border, 2),
    errorBorder: border(c.error, 2),
    focusedErrorBorder: border(c.error, 3),
    errorText: error,
    // An empty error draws the red outline alone; the screen writes the
    // sentence underneath with its icon.
    errorStyle: error == ''
        ? OgType.collapsed
        : context.type.body.copyWith(color: c.error),
  );
}

/// Outlined 56px text field whose label floats into the border (Q251).
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
    return OgInput(
      controller: controller,
      label: label,
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
    );
  }
}

/// The outlined input. [label] floats into the border; without one, give
/// [semanticLabel] so a screen reader can name it.
class OgInput extends StatelessWidget {
  const OgInput({
    super.key,
    required this.controller,
    this.label,
    this.prefix,
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
  final String? label;
  final Widget? prefix;
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
      label: label == null ? semanticLabel : null,
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
        style: context.type.body,
        decoration: ogOutlinedDecoration(
          context,
          label: label,
          hint: hint,
          error: error,
          valid: valid,
          prefix: prefix,
        ),
      ),
    );
  }
}

/// A field-looking button that opens a picker (country, month, level). With
/// [label] it is drawn in the outlined style, its label floating in the
/// border once a value is chosen.
class OgSelectField extends StatelessWidget {
  const OgSelectField({
    super.key,
    required this.value,
    required this.onTap,
    this.label,
    this.semanticLabel,
    this.leading,
    this.chevron = true,
    this.placeholder = false,
    this.height = 56,
  });

  final double height;
  final String? label;

  /// False for compact fields (day, year) where the chevron would crowd the value.
  final bool chevron;

  /// Shows [value] in the tertiary colour, as a placeholder.
  final bool placeholder;
  final String value;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final chevronIcon = Icon(
      Icons.keyboard_arrow_down_rounded,
      color: c.text,
      size: 22,
    );
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      value: placeholder ? null : value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: label != null
            ? ExcludeSemantics(
                child: InputDecorator(
                  isEmpty: placeholder,
                  decoration: ogOutlinedDecoration(
                    context,
                    label: label,
                    suffix: chevron ? chevronIcon : null,
                  ),
                  child: Text(
                    placeholder ? '' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.body,
                  ),
                ),
              )
            : Container(
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
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.body.copyWith(
                            color: placeholder ? c.textTertiary : c.text,
                          ),
                        ),
                      ),
                      if (chevron) chevronIcon,
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// The 6-digit code as one outlined field. It offers the code from Messages
/// or Mail above the keyboard and calls [onCompleted] once all six digits
/// are in, so typing or autofill both submit.
class OgCodeField extends StatefulWidget {
  const OgCodeField({
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
  State<OgCodeField> createState() => _OgCodeFieldState();
}

class _OgCodeFieldState extends State<OgCodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _changed() {
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
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      maxLength: widget.length,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: context.type.section.copyWith(letterSpacing: 6),
      decoration: ogOutlinedDecoration(
        context,
        label: '${widget.length}-digit code',
        error: widget.hasError ? '' : null,
      ).copyWith(counterText: ''),
    );
  }
}
