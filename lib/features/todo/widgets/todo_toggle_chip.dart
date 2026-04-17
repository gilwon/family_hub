import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TodoToggleChip extends StatelessWidget {
  const TodoToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return ShadButton(size: ShadButtonSize.sm, onPressed: onTap, child: Text(label));
    }
    return ShadButton.outline(size: ShadButtonSize.sm, onPressed: onTap, child: Text(label));
  }
}
