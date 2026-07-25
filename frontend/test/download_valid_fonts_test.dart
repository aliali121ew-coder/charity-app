import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('Download valid TTF fonts', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    print('Downloading Cairo-Regular via PdfGoogleFonts...');
    final regularFont = await PdfGoogleFonts.cairoRegular();
    File('assets/fonts/Cairo-Regular.ttf').writeAsBytesSync((regularFont as pw.TtfFont).data.buffer.asUint8List());
    
    print('Downloading Cairo-Bold via PdfGoogleFonts...');
    final boldFont = await PdfGoogleFonts.cairoBold();
    File('assets/fonts/Cairo-Bold.ttf').writeAsBytesSync((boldFont as pw.TtfFont).data.buffer.asUint8List());
    
    print('Fonts saved to assets.');
  });
}
