import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/settings_service.dart';
import 'providers/app_providers.dart';
import 'theme/app_theme.dart';
import 'pages/deploy_packager_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings service
  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    ProviderScope(
      overrides: [settingsServiceProvider.overrideWithValue(settingsService)],
      child: const DeployPackagerApp(),
    ),
  );
}

class DeployPackagerApp extends StatelessWidget {
  const DeployPackagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deploy Packager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DeployPackagerPage(),
    );
  }
}
