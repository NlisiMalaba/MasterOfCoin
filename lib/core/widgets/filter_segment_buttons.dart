import 'package:flutter/material.dart';

/// Filter-style segment buttons matching the design:
/// Selected: solid green background, white text.
/// Unselected: white/surface background, dark text, light grey border.
class FilterSegmentButtons<T> extends StatelessWidget {
  const FilterSegmentButtons({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final outline = theme.colorScheme.outline.withValues(alpha: 0.4);

    return Row(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final isSelected = value == selected;
        final isFirst = index == 0;
        final isLast = index == options.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isLast ? 0 : 8,
              left: isFirst ? 0 : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(value),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primary : outline,
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      labelBuilder(value),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
