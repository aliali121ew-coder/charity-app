import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand Gradients (for KPI cards — matches reference images) ──────────
  static const gradientTeal = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientPurple = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientOrange = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientPink = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientBlue = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientRed = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientIndigo = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Solid brand colors ───────────────────────────────────────────────────
  static const primary = Color(0xFF5B4FCF);
  static const secondary = Color(0xFF10B981);
  static const teal = Color(0xFF00C9A7);
  static const orange = Color(0xFFF59E0B);
  static const pink = Color(0xFFEC4899);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const indigo = Color(0xFF6366F1);

  // ── Semantic colors ──────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ── Light theme surfaces ─────────────────────────────────────────────────
  static const backgroundLight = Color(0xFFF1F5F9);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const dividerLight = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFE2E8F0);

  // ── Dark theme surfaces ──────────────────────────────────────────────────
  static const backgroundDark = Color(0xFF0A0F1E);
  static const surfaceDark = Color(0xFF111827);
  static const cardDark = Color(0xFF1A2035);
  static const dividerDark = Color(0xFF2D3748);
  static const borderDark = Color(0xFF374151);

  // ── Text colors ──────────────────────────────────────────────────────────
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textTertiaryLight = Color(0xFF94A3B8);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textTertiaryDark = Color(0xFF64748B);

  // ── Status chip backgrounds (soft tints) ────────────────────────────────
  static const statusActiveBg = Color(0xFFD1FAE5);
  static const statusActiveText = Color(0xFF065F46);
  static const statusPendingBg = Color(0xFFFEF3C7);
  static const statusPendingText = Color(0xFF92400E);
  static const statusInactiveBg = Color(0xFFF1F5F9);
  static const statusInactiveText = Color(0xFF475569);
  static const statusRejectedBg = Color(0xFFFEE2E2);
  static const statusRejectedText = Color(0xFF991B1B);
  static const statusApprovedBg = Color(0xFFDBEAFE);
  static const statusApprovedText = Color(0xFF1E40AF);

  // ── Action type colors (for log entries left border) ────────────────────
  static const logAdd = Color(0xFF10B981);
  static const logEdit = Color(0xFFF59E0B);
  static const logDelete = Color(0xFFEF4444);
  static const logApprove = Color(0xFF3B82F6);
  static const logReject = Color(0xFFEF4444);
  static const logDistribute = Color(0xFF7C3AED);
  static const logReport = Color(0xFF6366F1);
  static const logSettings = Color(0xFF64748B);
  static const logLogin = Color(0xFF00C9A7);

  // ── Chart colors ─────────────────────────────────────────────────────────
  static const chartColors = [
    Color(0xFF00C9A7),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF7C3AED),
    Color(0xFF10B981),
  ];

  // ── Drawer / Sidebar ─────────────────────────────────────────────────────
  static const drawerBgLight = Color(0xFFFFFFFF);
  static const drawerBgDark = Color(0xFF111827);
  static const drawerActiveLight = Color(0xFFEFF6FF);
  static const drawerActiveDark = Color(0xFF1E3A5F);

  // ── Extended brand (overrides for purple-primary UI) ─────────────────────
  static const primaryLight = Color(0xFF7C6FE0);
  static const primaryDark = Color(0xFF3D33A8);
  static const primaryContainer = Color(0xFFEDE9FF);
  static const secondaryContainer = Color(0xFFD1FAE5);
  static const errorContainer = Color(0xFFFEE2E2);
  static const successContainer = Color(0xFFD1FAE5);
  static const infoContainer = Color(0xFFDBEAFE);

  // ── Surface variants ─────────────────────────────────────────────────────
  static const surfaceVariantLight = Color(0xFFF1F5F9);
  static const surfaceVariantDark = Color(0xFF1E2235);

  // ── KPI gradient pairs (used in KpiStatCard) ─────────────────────────────
  static const List<Color> kpiBlue = [Color(0xFF3B82F6), Color(0xFF1D4ED8)];
  static const List<Color> kpiPurple = [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
  static const List<Color> kpiGreen = [Color(0xFF10B981), Color(0xFF047857)];
  static const List<Color> kpiOrange = [Color(0xFFF97316), Color(0xFFEA580C)];
  static const List<Color> kpiRose = [Color(0xFFF43F5E), Color(0xFFBE123C)];
  static const List<Color> kpiTeal = [Color(0xFF14B8A6), Color(0xFF0F766E)];
  static const List<Color> kpiIndigo = [Color(0xFF6366F1), Color(0xFF4338CA)];
  static const List<Color> kpiAmber = [Color(0xFFF59E0B), Color(0xFFD97706)];
}
