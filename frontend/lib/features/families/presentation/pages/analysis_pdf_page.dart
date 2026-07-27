import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/families/presentation/pages/families_page.dart'; // fetchLateSubscribersData() — Supabase-backed

class AnalysisPdfPage extends StatefulWidget {
  const AnalysisPdfPage({super.key});

  @override
  State<AnalysisPdfPage> createState() => _AnalysisPdfPageState();
}

class _AnalysisPdfPageState extends State<AnalysisPdfPage> {
  // Simple format currency helper
  String _formatCurrency(double amount) {
    final formatter = intl.NumberFormat('#,###', 'ar');
    return '${formatter.format(amount)} د.ع';
  }

  // Format month names to be descriptive
  String _formatMonthsRange(List<int> months) {
    if (months.isEmpty) return '';
    final monthNames = {
      1: 'كانون الثاني (1)',
      2: 'شباط (2)',
      3: 'آذار (3)',
      4: 'نيسان (4)',
      5: 'أيار (5)',
      6: 'حزيران (6)',
      7: 'تموز (7)',
      8: 'آب (8)',
      9: 'أيلول (9)',
      10: 'تشرين الأول (10)',
      11: 'تشرين الثاني (11)',
      12: 'كانون الأول (12)',
    };
    if (months.length == 1) {
      return monthNames[months.first] ?? 'شهر ${months.first}';
    }
    final startName = monthNames[months.first] ?? 'شهر ${months.first}';
    final endName = monthNames[months.last] ?? 'شهر ${months.last}';
    return '$startName - $endName';
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Load custom Arabic Cairo fonts from assets
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final cairoFont = pw.Font.ttf(fontData);

    final boldFontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final cairoBold = pw.Font.ttf(boldFontData);

    final pdfTheme = pw.ThemeData.withFont(
      base: cairoFont,
      bold: cairoBold,
    );

    // Fetch the list of overdue subscribers from Supabase (real data)
    final data = await fetchLateSubscribersData();

    // Compute metrics
    final totalLateCount = data.length;
    final totalAmountLate = data.fold<double>(
      0.0,
      (sum, item) => sum + ((item['monthlyAmount'] as double) * (item['unpaidMonths'] as List<int>).length),
    );
    final avgMonthsLate = totalLateCount == 0
        ? 0.0
        : data.fold<int>(0, (sum, item) => sum + (item['unpaidMonths'] as List<int>).length) / totalLateCount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: pdfTheme,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            // ── Header Section ──────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'تقرير المشتركين المتأخرين عن السداد لعام 2026',
                      style: pw.TextStyle(
                        font: cairoBold,
                        fontSize: 16,
                        color: PdfColor.fromHex('#5B4FCF'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'مؤسسة البر والاحسان الخيرية - نظام إدارة الاشتراكات',
                      style: pw.TextStyle(
                        font: cairoFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'تاريخ التقرير: ${intl.DateFormat('yyyy/MM/dd HH:mm', 'ar').format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: cairoFont,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Container(
              height: 2,
              color: PdfColor.fromHex('#5B4FCF'),
              margin: const pw.EdgeInsets.symmetric(vertical: 12),
            ),

            // ── KPI Summary Cards ─────────────────────────────────────────
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'إجمالي المشتركين المتأخرين',
                          style: pw.TextStyle(font: cairoFont, fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$totalLateCount',
                          style: pw.TextStyle(font: cairoBold, fontSize: 16, color: PdfColors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.red200, width: 0.5),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'إجمالي المبالغ المتأخرة',
                          style: pw.TextStyle(font: cairoFont, fontSize: 9, color: PdfColors.red700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _formatCurrency(totalAmountLate),
                          style: pw.TextStyle(font: cairoBold, fontSize: 16, color: PdfColors.red900),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'متوسط أشهر التأخير',
                          style: pw.TextStyle(font: cairoFont, fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${avgMonthsLate.toStringAsFixed(1)} أشهر',
                          style: pw.TextStyle(font: cairoBold, fontSize: 16, color: PdfColors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Overdue Subscribers Table ─────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(30),  // #
                1: pw.FlexColumnWidth(3),    // Subscriber Name
                2: pw.FlexColumnWidth(3),    // Delegate Name
                3: pw.FlexColumnWidth(2),    // Monthly Amount
                4: pw.FlexColumnWidth(3.5),  // Unpaid Months Range/Count
                5: pw.FlexColumnWidth(2.5),  // Total Overdue
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#5B4FCF')),
                  children: [
                    _buildHeaderCell('#', cairoBold),
                    _buildHeaderCell('اسم المشترك', cairoBold),
                    _buildHeaderCell('المندوب', cairoBold),
                    _buildHeaderCell('القسط الشهري', cairoBold),
                    _buildHeaderCell('أشهر التأخير (2026)', cairoBold),
                    _buildHeaderCell('المبلغ المتأخر', cairoBold),
                  ],
                ),
                // Data rows
                ...data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isEven = index % 2 == 0;
                  final subscriberName = item['subscriberName'] as String;
                  final delegateName = item['delegateName'] as String;
                  final monthlyAmount = item['monthlyAmount'] as double;
                  final unpaidMonths = item['unpaidMonths'] as List<int>;
                  final unpaidCount = unpaidMonths.length;
                  final totalOverdue = monthlyAmount * unpaidCount;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey100 : PdfColors.white),
                    children: [
                      _buildCell((index + 1).toString(), cairoFont, align: pw.TextAlign.center),
                      _buildCell(subscriberName, cairoFont),
                      _buildCell(delegateName, cairoFont),
                      _buildCell(_formatCurrency(monthlyAmount), cairoFont, align: pw.TextAlign.left),
                      _buildCell(_formatMonthsRange(unpaidMonths), cairoFont, align: pw.TextAlign.center),
                      _buildCell(_formatCurrency(totalOverdue), cairoFont, align: pw.TextAlign.left),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(top: 15),
            child: pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: pw.TextStyle(font: cairoFont, fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeaderCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.right}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: 8.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تصدير تقرير PDF / معاينة الطباعة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        loadingWidget: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        pdfPreviewPageDecoration: const BoxDecoration(),
      ),
    );
  }
}
