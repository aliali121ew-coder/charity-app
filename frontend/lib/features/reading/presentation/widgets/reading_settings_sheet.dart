import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/features/reading/domain/reading_preferences.dart';
import 'package:charity_app/features/reading/presentation/providers/reading_preferences_provider.dart';

/// لوحة إعدادات القراءة: حجم الخط ونوعه والخلفية وطريقة التصفّح.
/// تُستخدم من قارئ الأدعية/الزيارات/الأعمال وقارئ القرآن على حدّ سواء.
class ReadingSettingsSheet extends ConsumerWidget {
  final Color accent;

  /// إخفاء خيار طريقة التصفّح (يُمرَّر true لقارئ القرآن الذي يبقى تمريراً).
  final bool showModeOption;

  const ReadingSettingsSheet({super.key, required this.accent, this.showModeOption = true});

  static Future<void> show(BuildContext context, {required Color accent, bool showModeOption = true}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadingSettingsSheet(accent: accent, showModeOption: showModeOption),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readingPreferencesProvider);
    final notifier = ref.read(readingPreferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1A2035) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: accent),
                  const SizedBox(width: 10),
                  Text('إعدادات القراءة',
                      style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w900, color: textColor)),
                ],
              ),
              const SizedBox(height: 20),

              // ── حجم الخط ──
              _Label(text: 'حجم الخط', color: subColor),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RoundBtn(icon: Icons.remove_rounded, accent: accent, onTap: notifier.decreaseFont),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        thumbColor: accent,
                        overlayColor: accent.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: prefs.fontSize,
                        min: ReadingPreferences.minFontSize,
                        max: ReadingPreferences.maxFontSize,
                        divisions: ((ReadingPreferences.maxFontSize - ReadingPreferences.minFontSize) / 2).round(),
                        label: prefs.fontSize.toStringAsFixed(0),
                        onChanged: notifier.setFontSize,
                      ),
                    ),
                  ),
                  _RoundBtn(icon: Icons.add_rounded, accent: accent, onTap: notifier.increaseFont),
                ],
              ),
              const SizedBox(height: 16),

              // ── نوع الخط ──
              _Label(text: 'نوع الخط', color: subColor),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReadingFont.values.map((f) {
                  final selected = f == prefs.font;
                  return _Chip(
                    label: f.label,
                    selected: selected,
                    accent: accent,
                    textColor: textColor,
                    labelStyle: f.style(fontSize: 14, height: 1.2, color: selected ? Colors.white : textColor),
                    onTap: () => notifier.setFont(f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── الخلفية ──
              _Label(text: 'لون الخلفية', color: subColor),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ReadingBackground.values.map((b) {
                  final selected = b == prefs.background;
                  return _BackgroundSwatch(
                    background: b,
                    selected: selected,
                    accent: accent,
                    onTap: () => notifier.setBackground(b),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── طريقة التصفّح ──
              if (showModeOption) ...[
                _Label(text: 'طريقة التصفّح', color: subColor),
                const SizedBox(height: 10),
                Row(
                  children: ReadingMode.values.map((m) {
                    final selected = m == prefs.mode;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _ModeTile(
                          mode: m,
                          selected: selected,
                          accent: accent,
                          textColor: textColor,
                          onTap: () => notifier.setMode(m),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: color));
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: accent, size: 20)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color textColor;
  final TextStyle labelStyle;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.textColor,
    required this.labelStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(label, style: labelStyle.copyWith(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _BackgroundSwatch extends StatelessWidget {
  final ReadingBackground background;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _BackgroundSwatch({
    required this.background,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: background.pageColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? accent : Colors.black.withValues(alpha: 0.12),
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Center(
              child: Text('أ', style: TextStyle(color: background.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              background.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? accent : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final ReadingMode mode;
  final bool selected;
  final Color accent;
  final Color textColor;
  final VoidCallback onTap;
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.accent,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = mode == ReadingMode.scroll ? Icons.swap_vert_rounded : Icons.auto_stories_rounded;
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? accent : textColor.withValues(alpha: 0.15), width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? accent : textColor.withValues(alpha: 0.7), size: 26),
              const SizedBox(height: 6),
              Text(mode.label,
                  style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? accent : textColor.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ),
    );
  }
}
