import 'dart:io';

void main() async {
  final regularUrl = 'https://github.com/googlefonts/cairo/raw/master/fonts/ttf/Cairo-Regular.ttf';
  final boldUrl = 'https://github.com/googlefonts/cairo/raw/master/fonts/ttf/Cairo-Bold.ttf';
  
  final dir = Directory('assets/fonts');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  
  print('Downloading Cairo-Regular...');
  final client = HttpClient();
  final regReq = await client.getUrl(Uri.parse(regularUrl));
  final regRes = await regReq.close();
  await regRes.pipe(File('assets/fonts/Cairo-Regular.ttf').openWrite());
  
  print('Downloading Cairo-Bold...');
  final boldReq = await client.getUrl(Uri.parse(boldUrl));
  final boldRes = await boldReq.close();
  await boldRes.pipe(File('assets/fonts/Cairo-Bold.ttf').openWrite());
  
  print('Fonts downloaded successfully!');
  exit(0);
}
