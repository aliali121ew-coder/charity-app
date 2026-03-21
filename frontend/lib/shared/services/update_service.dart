import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

const _apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://charity-backend-production-0223.up.railway.app',
);

Future<void> checkForUpdate(BuildContext context) async {
  try {
    final res = await http
        .get(Uri.parse('$_apiBase/api/version'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final latestVersion = data['version'] as String? ?? '1.0.0';
    final downloadUrl = data['download_url'] as String? ?? '';
    final forceUpdate = data['force_update'] as bool? ?? false;

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (_isNewer(latestVersion, currentVersion) && forceUpdate) {
      if (context.mounted) {
        await _showUpdateDialog(context, latestVersion, downloadUrl);
      }
    }
  } catch (_) {
    // تجاهل أخطاء الشبكة - لا نمنع الدخول
  }
}

bool _isNewer(String latest, String current) {
  final l = latest.split('.').map(int.parse).toList();
  final c = current.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    final lv = i < l.length ? l[i] : 0;
    final cv = i < c.length ? c[i] : 0;
    if (lv > cv) return true;
    if (lv < cv) return false;
  }
  return false;
}

Future<void> _showUpdateDialog(
    BuildContext context, String version, String downloadUrl) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('تحديث إجباري'),
        content: Text(
          'يوجد إصدار جديد ($version) يجب تثبيته للمتابعة.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (downloadUrl.isNotEmpty) {
                await launchUrl(
                  Uri.parse(downloadUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    ),
  );
}
