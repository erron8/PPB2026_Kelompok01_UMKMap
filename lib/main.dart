import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/supabase_client.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/umkm_provider.dart';
import 'utils/app_router.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppColors.primary);
    const secondary = Color(AppColors.secondary);
    const background = Color(AppColors.background);
    const error = Color(AppColors.error);
    final colorScheme = ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      secondary: secondary,
      error: error,
      surface: Colors.white,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),
        ChangeNotifierProvider(create: (_) => UmkmProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: colorScheme,
              scaffoldBackgroundColor: background,
              appBarTheme: const AppBarTheme(
                backgroundColor: background,
                foregroundColor: Colors.black87,
                centerTitle: false,
              ),
              cardTheme: CardThemeData(
                color: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: colorScheme.inverseSurface,
                contentTextStyle: TextStyle(
                  color: colorScheme.onInverseSurface,
                ),
              ),
              useMaterial3: true,
            ),
            routerConfig: createAppRouter(authProvider),
          );
        },
      ),
    );
  }
}
