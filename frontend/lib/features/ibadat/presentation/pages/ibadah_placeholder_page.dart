import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charity_app/core/theme/app_colors.dart';

/// شاشة مبدئية لأقسام العبادات التي ستُبنى تباعاً.
class IbadahPlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const IbadahPlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Icon(icon, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 22),
              Text(title,
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text('هذا القسم قيد الإعداد وسيتوفّر قريباً بإذن الله.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 13, height: 1.6,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ],
          ),
        ),
      ),
    );
  }
}
