import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/devotions/domain/devotional_models.dart';
import 'package:charity_app/features/devotions/presentation/pages/devotional_reader_page.dart';
import 'package:charity_app/features/devotions/presentation/providers/devotional_favorites_provider.dart';

/// شاشة عامة تعرض قائمة النصوص داخل تصنيف واحد، مع بحث سريع وأيقونة مفضّلة.
class DevotionalItemsPage extends ConsumerStatefulWidget {
  final DevotionalSection section;
  final DevotionalCategory category;
  const DevotionalItemsPage({super.key, required this.section, required this.category});

  @override
  ConsumerState<DevotionalItemsPage> createState() => _DevotionalItemsPageState();
}

class _DevotionalItemsPageState extends ConsumerState<DevotionalItemsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = ref.watch(devotionalFavoritesProvider)[widget.section.namespace] ?? {};
    final q = _query.trim();
    final items = q.isEmpty
        ? widget.category.items
        : widget.category.items.where((it) => it.title.contains(q) || it.body.contains(q)).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.category.title, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _SearchField(onChanged: (v) => setState(() => _query = v), isDark: isDark, color: widget.section.color),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Center(
                child: Text('لا توجد نتائج مطابقة',
                    style: GoogleFonts.cairo(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ),
            ),
          ...items.map((it) => _ItemTile(
                item: it,
                color: widget.section.color,
                isDark: isDark,
                isFavorite: favorites.contains(it.id),
                onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                  builder: (_) => DevotionalReaderPage(section: widget.section, item: it),
                )),
                onToggleFavorite: () =>
                    ref.read(devotionalFavoritesProvider.notifier).toggle(widget.section.namespace, it.id),
              )),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool isDark;
  final Color color;
  const _SearchField({required this.onChanged, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: TextField(
        onChanged: onChanged,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'ابحث في هذا التصنيف...',
          hintStyle: GoogleFonts.cairo(fontSize: 12.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
          prefixIcon: Icon(Icons.search_rounded, color: color, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final DevotionalItem item;
  final Color color;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  const _ItemTile({
    required this.item, required this.color, required this.isDark,
    required this.isFavorite, required this.onTap, required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(width: 4, height: 34, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      if (item.occasion != null) ...[
                        const SizedBox(height: 2),
                        Text(item.occasion!,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 10.5,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? const Color(0xFFF59E0B) : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
