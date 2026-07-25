import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await Printing.info();
  print('--- PRINTING INFO ---');
  print('canPrint: ${info.canPrint}');
  print('canShare: ${info.canShare}');
  print('canRaster: ${info.canRaster}');
  print('canListPrinters: ${info.canListPrinters}');
  print('---------------------');
  File('printing_info.txt').writeAsStringSync('canRaster: ${info.canRaster}\ncanPrint: ${info.canPrint}');
  exit(0);
}
