import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';

/// 關於頁：App 版本、阿忠小站連結與原作者說明 (沿用最早 Android 版 MainActivity5)
class LegacyAboutScreen extends StatelessWidget {
  const LegacyAboutScreen({super.key});

  Future<void> _launchSite(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.aboutTitle),
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 佛像或圖示
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 96,
                  height: 96,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.spa,
                    size: 80,
                    color: Color(0xFF0000FF),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                context.l10n.aboutAppName,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.48.0';
                  return Text(
                    context.l10n.aboutVersion(version),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  );
                },
              ),

              const Divider(height: 32),

              Text(
                context.l10n.aboutHeading,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0000FF),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                context.l10n.aboutBody,
                textAlign: TextAlign.start,
                style: const TextStyle(
                    fontSize: 16, height: 1.6, color: Colors.black87),
              ),

              const SizedBox(height: 24),

              // 父親原網站連結
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: Text(context.l10n.aboutVisitSite),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0000FF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _launchSite('https://www.leeyc.net/phpBB3/'),
              ),

              const SizedBox(height: 12),

              // 隱私權政策 (iOS & Android 版合規要求)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                    label: Text(context.l10n.aboutPrivacyIos),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0000FF),
                    ),
                    onPressed: () => _launchSite(
                      'https://www.leeyc.net/share/buddhacounter/iOS/privacy_policy.html',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                    label: Text(context.l10n.aboutPrivacyAndroid),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0000FF),
                    ),
                    onPressed: () => _launchSite(
                      'https://www.leeyc.net/share/buddhacounter/Android/privacy_policy.html',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.commonBack,
                    style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
