import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';

class ZoomControlButton extends ConsumerWidget {
  const ZoomControlButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final zoom = ref.watch(zoomProvider);
    final pct = (zoom.currentScale * 100).round();
    final label = zoom.isAuto ? 'Auto ($pct%)' : '$pct%';

    return PopupMenuButton<String>(
      tooltip: 'Display Zoom Settings (Ctrl + / - / 0)',
      offset: const Offset(0, 44),
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.onSurface.withValues(alpha: 0.1)),
      ),
      onSelected: (val) {
        final notifier = ref.read(zoomProvider.notifier);
        switch (val) {
          case 'auto':
            notifier.setAuto();
            break;
          case 'zoom_in':
            notifier.zoomIn();
            break;
          case 'zoom_out':
            notifier.zoomOut();
            break;
          case '75':
            notifier.setScale(0.75);
            break;
          case '85':
            notifier.setScale(0.85);
            break;
          case '100':
            notifier.setScale(1.0);
            break;
          case '115':
            notifier.setScale(1.15);
            break;
          case '125':
            notifier.setScale(1.25);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          // Stepper row header
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(zoomProvider.notifier).zoomOut();
                  },
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  tooltip: 'Zoom Out (Ctrl -)',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(zoomProvider.notifier).zoomIn();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  tooltip: 'Zoom In (Ctrl +)',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // Auto option
          PopupMenuItem<String>(
            value: 'auto',
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: zoom.isAuto ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Auto (Responsive)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: zoom.isAuto ? FontWeight.w600 : FontWeight.w400,
                      color: zoom.isAuto ? colors.primary : colors.onSurface,
                    ),
                  ),
                ),
                if (zoom.isAuto)
                  Icon(Icons.check_rounded, size: 16, color: colors.primary),
              ],
            ),
          ),
          const PopupMenuDivider(),
          _buildPresetItem('75', '75%', zoom, colors),
          _buildPresetItem('85', '85%', zoom, colors),
          _buildPresetItem('100', '100% (Default)', zoom, colors),
          _buildPresetItem('115', '115%', zoom, colors),
          _buildPresetItem('125', '125%', zoom, colors),
        ];
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: zoom.isAuto
                ? colors.primary.withValues(alpha: 0.3)
                : colors.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              zoom.isAuto ? Icons.auto_awesome_rounded : Icons.aspect_ratio_rounded,
              size: 16,
              color: zoom.isAuto ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: zoom.isAuto ? colors.primary : colors.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPresetItem(
    String val,
    String text,
    ZoomState zoom,
    ColorScheme colors,
  ) {
    final scale = double.parse(val) / 100.0;
    final isSelected = !zoom.isAuto && (zoom.manualScale - scale).abs() < 0.01;

    return PopupMenuItem<String>(
      value: val,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_rounded, size: 16, color: colors.primary),
        ],
      ),
    );
  }
}
