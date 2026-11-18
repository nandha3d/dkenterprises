import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show PlatformDispatcher, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_models.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Install crash net & error handlers
  FlutterError.onError = (details) {
    debugPrint('FLUTTER_ERROR_EXACT: ${details.exceptionAsString()}');
    debugPrint('FLUTTER_STACK_EXACT:\n${details.stack}');
    try {
      FlutterError.presentError(details);
    } catch (_) {}
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    return true; // prevent process exit
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.amber, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong while rendering this view.',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize SQLite for Desktop (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const ZoloErpApp(),
    ),
  );
}

class ZoloErpApp extends ConsumerStatefulWidget {
  const ZoloErpApp({super.key});

  @override
  ConsumerState<ZoloErpApp> createState() => _ZoloErpAppState();
}

class _ZoloErpAppState extends ConsumerState<ZoloErpApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pushService = ref.read(pushNotificationServiceProvider);
      pushService.onNavigate = (route) => ref.read(appRouterProvider).push(route);
      ref.read(keepAliveManagerProvider).attach();
      final authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated) {
        pushService.start();
        ref.read(gpsPingerProvider).syncSession(authState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(
      authNotifierProvider,
      (prev, next) {
        final pushService = ref.read(pushNotificationServiceProvider);
        if (next.isAuthenticated) {
          pushService.start();
        } else {
          pushService.stop();
        }
        ref.read(gpsPingerProvider).syncSession(next);
      },
    );

    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final rippleRole = ref.watch(activeRippleRoleProvider);

    return MaterialApp.router(
      title: 'DK Enterprises ERP',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.themeForRole(rippleRole, Brightness.light),
      darkTheme: AppTheme.themeForRole(rippleRole, Brightness.dark),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
