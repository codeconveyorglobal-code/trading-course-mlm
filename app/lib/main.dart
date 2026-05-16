import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_router.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/mlm_provider.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TradingMLMApp());
}

class TradingMLMApp extends StatelessWidget {
  const TradingMLMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<ApiService>()),
          update: (ctx, api, prev) => prev ?? AuthProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, CourseProvider>(
          create: (ctx) => CourseProvider(ctx.read<ApiService>()),
          update: (ctx, api, prev) => prev ?? CourseProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, MLMProvider>(
          create: (ctx) => MLMProvider(ctx.read<ApiService>()),
          update: (ctx, api, prev) => prev ?? MLMProvider(api),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'TradeMLM',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.router(auth),
          );
        },
      ),
    );
  }
}
