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
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(AppColors.primary),
              ),
              scaffoldBackgroundColor: const Color(AppColors.background),
              useMaterial3: true,
            ),
            routerConfig: createAppRouter(authProvider),
          );
        },
      ),
    );
  }
}
