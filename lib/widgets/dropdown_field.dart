import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optica_sana/themes/app_theme.dart';

/// A reusable dropdown field backed by a list of string options.
///
/// [compact] = true  → used inside table cells (fixed width, no label/border)
/// [compact] = false → used in forms (full width with label and border)
class DropdownField extends StatefulWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final bool compact;
  final double? width;

  /// Optional mapper: converts stored value to display text (e.g. dominant_eye).
  final String Function(String)? displayMapper;

  /// When provided, the parent owns this controller and free-text input is
  /// captured automatically. [value] and [onChanged] are then not required.
  final TextEditingController? controller;

  /// Optional text-input formatters applied to the underlying text field,
  /// so callers can combine dropdown suggestions with input masks.
  final List<TextInputFormatter>? inputFormatters;

  const DropdownField({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.compact = false,
    this.width,
    this.displayMapper,
    this.controller,
    this.inputFormatters,
  });

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  // DropdownMenu must *always* be given its own controller. Sharing a
  // controller with a widget that is being unmounted (e.g. a TextFormField
  // in view mode) triggers "Cannot get renderObject of inactive element"
  // because DropdownMenu.initState writes to the controller, which still
  // has the old widget's EditableText as a listener.
  late final TextEditingController _internal;

  @override
  void initState() {
    super.initState();
    _internal = TextEditingController(text: _initialText());
    _internal.addListener(_syncToExternal);
    widget.controller?.addListener(_syncFromExternal);
  }

  @override
  void didUpdateWidget(DropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_syncFromExternal);
      widget.controller?.addListener(_syncFromExternal);
    }
    if (widget.controller == null && oldWidget.value != widget.value) {
      final displayed = _display(widget.value) ?? '';
      if (_internal.text != displayed) _internal.text = displayed;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncFromExternal);
    _internal.removeListener(_syncToExternal);
    _internal.dispose();
    super.dispose();
  }

  void _syncFromExternal() {
    final ext = widget.controller!.text;
    if (_internal.text != ext) _internal.text = ext;
  }

  void _syncToExternal() {
    final ext = widget.controller;
    if (ext == null) return;
    if (ext.text != _internal.text) ext.text = _internal.text;
  }

  String _initialText() {
    if (widget.controller != null) return widget.controller!.text;
    return _display(widget.value) ?? '';
  }

  String? _display(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return widget.displayMapper != null ? widget.displayMapper!(raw) : raw;
  }

  void _handleSelected(String? v) {
    widget.onChanged?.call(v);
    if (widget.controller != null &&
        v != null &&
        widget.controller!.text != v) {
      widget.controller!.text = v;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.options
        .map(
          (opt) => DropdownMenuEntry<String>(
            value: opt,
            label: _display(opt) ?? opt,
          ),
        )
        .toList();

    final initialSelection =
        widget.value ??
        (widget.controller?.text.isNotEmpty == true
            ? widget.controller!.text
            : null);

    if (widget.compact) {
      // Shrink the trailing dropdown arrow so the input text has more room
      // inside narrow table cells. Without this, DropdownMenu reserves ~48px
      // for the arrow and clips the value on cells that are only ~90px wide.
      const smallArrow = Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.arrow_drop_down, size: 18, color: AppColors.label),
      );
      const smallArrowUp = Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.arrow_drop_up, size: 18, color: AppColors.label),
      );
      return DropdownMenu<String>(
        controller: _internal,
        width: widget.width,
        // When no explicit width is given, stretch to the parent's width so
        // the trailing arrow sits at the right edge of the table cell instead
        // of floating in the middle with empty margins on either side.
        expandedInsets: widget.width == null ? EdgeInsets.zero : null,
        dropdownMenuEntries: entries,
        inputFormatters: widget.inputFormatters,
        initialSelection: initialSelection,
        onSelected: _handleSelected,
        trailingIcon: smallArrow,
        selectedTrailingIcon: smallArrowUp,
        menuStyle: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.fromLTRB(4, 4, 0, 4),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIconConstraints: BoxConstraints(
            minWidth: 22,
            minHeight: 22,
            maxWidth: 22,
            maxHeight: 28,
          ),
        ),
        textStyle: const TextStyle(fontSize: 12, color: AppColors.inputValue),
      );
    }

    return DropdownMenu<String>(
      controller: _internal,
      width: widget.width,
      expandedInsets: widget.width == null ? EdgeInsets.zero : null,
      label: widget.label != null ? Text(widget.label!) : null,
      dropdownMenuEntries: entries,
      inputFormatters: widget.inputFormatters,
      initialSelection: initialSelection,
      onSelected: _handleSelected,
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      textStyle: AppTextStyles.input(weight: FontWeight.normal),
    );
  }
}
