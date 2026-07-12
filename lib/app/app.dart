import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'theme.dart';
import '../core/providers/auth_provider.dart';

class EduManufacturingApp extends StatelessWidget {
  const EduManufacturingApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final router = AppRouter.createRouter(auth);
        return MaterialApp.router(
          title: 'edu-Manufacturing',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
