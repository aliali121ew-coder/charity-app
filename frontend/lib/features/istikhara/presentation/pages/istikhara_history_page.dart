import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/istikhara/domain/istikhara_models.dart';
import 'package:charity_app/features/istikhara/presentation/providers/istikhara_providers.dart';
import 'package:charity_app/features/istikhara/presentation/widgets/istikhara_shared.dart';

/// سجلّ الاستخارات المحفوظة، مع إمكانية الحذف وعرض التفاصيل.
class IstikharaHistoryPage extends ConsumerWidget {
  const IstikharaHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final records = ref.watch(istikharaHistoryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('سجلّ الاستخارات', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          if (records.isNotEmpty)
            IconButton(
              tooltip: 'حذف الكل',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 64, color: istikharaAccent.withValues(alpha: 0.5)),
                  const SizedBox(height: 14),
                  Text('لا توجد استخارات محفوظة',
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  const SizedBox(height: 6),
                  Text('احفظ نتيجة استخارتك لترجع إليها لاحقاً',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: records.length,
              itemBuilder: (context, i) => _RecordTile(
                record: records[i],
                isDark: isDark,
                onDelete: () => ref.read(istikharaHistoryProvider.notifier).remove(records[i].id),
                onTap: () => _showDetail(context, records[i], isDark),
              ),
            ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('حذف كل السجلّ؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('سيُحذف كل سجلّ الاستخارات نهائياً.', style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(istikharaHistoryProvider.notifier).clear();
              Navigator.of(ctx).pop();
            },
            child: Text('حذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, IstikharaRecord r, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(r.title, style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w900, color: istikharaAccent)),
              const SizedBox(height: 4),
              Text('${r.method.label} • ${_fmt(r.timestamp)}',
                  style: GoogleFonts.cairo(fontSize: 11.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              const SizedBox(height: 16),
              IstikharaResultView(result: r.result, detail: r.detail, commentary: r.commentary),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(int ms) =>
      DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));
}

class _RecordTile extends StatelessWidget {
  final IstikharaRecord record;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _RecordTile({required this.record, required this.isDark, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: record.result.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                  child: Icon(record.result.icon, color: record.result.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      const SizedBox(height: 2),
                      Text('${record.result.label} • ${record.method.label}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 11, color: record.result.color, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
