import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:optica_sana/themes/app_theme.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app_info_screen_title'.tr())),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1024,
                    maxHeight: 500,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 100,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Optica Sana',
                  style: TextStyle(
                    color: Color(0xFF0D1B2A),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                if (_version.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'app_info_version'.tr(namedArgs: {'version': _version}),
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 36),
                // Divider
                Container(
                  width: 80,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0),
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'app_info_description'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'app_info_copyright'.tr(),
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
