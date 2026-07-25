import 'package:printing/printing.dart';
void main() async {
  final font = await PdfGoogleFonts.cairoRegular();
  print(font);
}
