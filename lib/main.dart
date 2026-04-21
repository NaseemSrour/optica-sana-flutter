import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:optica_sana/db_flutter/bootstrap.dart';
import 'package:optica_sana/db_flutter/repositories/contact_lenses_repo.dart';
import 'package:optica_sana/db_flutter/repositories/customer_repo.dart';
import 'package:optica_sana/db_flutter/repositories/glasses_repo.dart';
import 'package:optica_sana/flutter_services/app_settings.dart';
import 'package:optica_sana/flutter_services/customer_service.dart';
import 'package:optica_sana/flutter_services/sound_service.dart';
import 'package:optica_sana/screens/welcome_screen.dart';
import 'package:optica_sana/themes/app_theme.dart';
import 'package:optica_sana/widgets/restart_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await EasyLocalization.ensureInitialized();
  await DatabaseHelper.instance.database;
  await SoundService.instance.init();
  await AppSettings.instance.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('he'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const RestartWidget(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final customerRepo = CustomerRepo();
    final glassesRepo = GlassesRepo();
    final lensesRepo = ContactLensesTestRepo();
    final customerService = CustomerService(
      customerRepo,
      glassesRepo,
      lensesRepo,
    );

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        title: 'OptiSana',
        localizationsDelegates: [
          ...context.localizationDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.themeData,
        home: WelcomeScreen(customerService: customerService),
      ),
    );
  }
}
