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

    // نأخذ الـ AuthProvider بدون استماع (listen: false)
    // حتى يتم إنشاء الـ GoRouter مرة واحدة فقط عند تشغيل التطبيق
    // ولا يتم إعادته وتدمير الـ navigation stack مع كل تغيير في الـ AuthProvider
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final router = AppRouter.createRouter(auth);

    return MaterialApp.router(
      title: 'edu-Manufacturing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
