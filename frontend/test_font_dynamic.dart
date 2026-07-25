import 'dart:io';
import 'package:printing/printing.dart';

void main() async {
  try {
    final font = await PdfGoogleFonts.cairoRegular();
    print('Type: ${font.runtimeType}');
    
    // Using dynamic to bypass static type checking and access the underlying properties
    final dynamic dynamicFont = font;
    
    try {
      final data = dynamicFont.data;
      print('Has data getter. Length: ${data.lengthInBytes}');
    } catch (e) {
      print('No data getter: $e');
    }
    
    try {
      final bytes = dynamicFont.bytes;
      print('Has bytes getter. Length: ${bytes.lengthInBytes}');
    } catch (e) {
      print('No bytes getter: $e');
    }
    
    exit(0);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
