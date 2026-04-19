import 'package:flutter/material.dart';
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
  });

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  TextEditingController? _ownedController;

  // Returns the external controller if provided, otherwise the one we created.
  TextEditingController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = TextEditingController(text: _display(widget.value));
    }
  }

  @override
  void didUpdateWidget(DropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync if we own the controller — if the parent owns it, they manage it.
    if (widget.controller != null) return;
    if (oldWidget.value != widget.value) {
      final displayed = _display(widget.value);
      if (_controller.text != displayed) {
        _controller.text = displayed ?? '';
      }
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose(); // never dispose an external controller
    super.dispose();
  }

  String? _display(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return widget.displayMapper != null ? widget.displayMapper!(raw) : raw;
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

    if (widget.compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = widget.width ?? constraints.maxWidth;
          return DropdownMenu<String>(
            controller: _controller,
            width: w.isFinite ? w : 90.0,
            dropdownMenuEntries: entries,
            initialSelection: widget.value ??
                (widget.controller?.text.isNotEmpty == true
                    ? widget.controller!.text
                    : null),
            onSelected: (v) => widget.onChanged?.call(v),
            menuStyle: const MenuStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.inputValue,
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = widget.width ?? constraints.maxWidth;
        return DropdownMenu<String>(
          controller: _controller,
          width: w.isFinite ? w : 200,
          label: widget.label != null ? Text(widget.label!) : null,
          dropdownMenuEntries: entries,
          initialSelection: widget.value ??
              (widget.controller?.text.isNotEmpty == true
                  ? widget.controller!.text
                  : null),
          onSelected: (v) {
            widget.onChanged?.call(v);
          },
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          textStyle: const TextStyle(color: AppColors.inputValue),
        );
      },
    );
  }
}
