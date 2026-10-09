import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 經典阿忠小站與傳承說明頁面 (忠實延續原 MainActivity5 / 李一中居士的心血結晶)
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
        title: const Text('阿忠小站'),
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

              const Text(
                '念佛計數器 (BuddhaCounter)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.48.0';
                  return Text(
                    '版本 $version',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  );
                },
              ),

              const Divider(height: 32),

              const Text(
                '【 阿忠小站 · 緣起與傳承 】',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0000FF),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                '本應用程式由李義忠（阿忠）居士發心設計開發，最初於 Android 早期發布，旨在提供十方念佛、拜佛同修一個方便、純粹的隨身修持記數工具。\n\n'
                '為使阿忠的心血得以長久傳承、並服務更多現代修行大眾，現由後輩工程師接棒維護，推出全新的操作介面。\n\n'
                '祈願一切見聞者，皆發菩提心，一向專念南無阿彌陀佛，同生極樂國。',
                textAlign: TextAlign.start,
                style:
                    TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),

              const SizedBox(height: 24),

              // 父親原網站連結
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('瀏覽阿忠小站 (https://www.leeyc.net)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0000FF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _launchSite('https://www.leeyc.net/phpBB3/'),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('返回', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
