import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      child: const _UmkmapApp(),
    );
  }
}

class _UmkmapApp extends StatefulWidget {
  const _UmkmapApp();

  @override
  State<_UmkmapApp> createState() => _UmkmapAppState();
}

class _UmkmapAppState extends State<_UmkmapApp> {
  late final GoRouter _router = createAppRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppColors.primary);
    const onPrimary = Color(AppColors.onPrimary);
    const secondary = Color(AppColors.secondary);
    const onSecondary = Color(AppColors.onSecondary);
    const primaryContainer = Color(AppColors.primaryContainer);
    const onPrimaryContainer = Color(AppColors.onPrimaryContainer);
    const background = Color(AppColors.background);
    const surface = Color(AppColors.surface);
    const fieldFill = Color(AppColors.fieldFill);
    const hairline = Color(AppColors.hairline);
    const error = Color(AppColors.error);
    const textPrimary = Color(AppColors.textPrimary);
    const textMuted = Color(AppColors.textMuted);
    const textSubtle = Color(AppColors.textSubtle);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          secondary: secondary,
          onSecondary: onSecondary,
          primaryContainer: primaryContainer,
          onPrimaryContainer: onPrimaryContainer,
          error: error,
          surface: surface,
          onSurface: textPrimary,
          outline: textSubtle,
          outlineVariant: hairline,
        );
    final baseTheme = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    final textTheme = baseTheme.textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: textPrimary,
          centerTitle: false,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusCard),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: primary,
            foregroundColor: onPrimary,
            disabledBackgroundColor: primary.withValues(alpha: 0.35),
            disabledForegroundColor: onPrimary.withValues(alpha: 0.74),
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            shape: const StadiumBorder(),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: primary,
            side: const BorderSide(color: hairline),
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            shape: const StadiumBorder(),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            shape: const StadiumBorder(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fieldFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusPill),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusPill),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusPill),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusPill),
            borderSide: const BorderSide(color: error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusPill),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: primary,
          disabledColor: hairline,
          secondarySelectedColor: primary,
          shape: const StadiumBorder(side: BorderSide(color: hairline)),
          side: const BorderSide(color: hairline),
          labelStyle: textTheme.bodySmall?.copyWith(color: textMuted),
          secondaryLabelStyle: textTheme.bodySmall?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          dragHandleColor: const Color(AppColors.dragHandle),
          dragHandleSize: const Size(36, 4),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadii.radiusSheet),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusSheet),
          ),
          titleTextStyle: textTheme.titleMedium?.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primary,
          contentTextStyle: textTheme.bodyMedium?.copyWith(color: onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: StadiumBorder(),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return null;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
        ),
        searchBarTheme: SearchBarThemeData(
          backgroundColor: const WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(
            textPrimary.withValues(alpha: 0.08),
          ),
          elevation: const WidgetStatePropertyAll(1),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
          hintStyle: WidgetStatePropertyAll(
            textTheme.bodyMedium?.copyWith(color: textSubtle),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
