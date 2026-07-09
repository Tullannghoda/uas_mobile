import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/local_storage_service.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/forgot_password.dart';
import 'core/services/supabase_service.dart';

import 'features/main_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.init();
  await SupabaseService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget { // ✅ FIX
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // ✅ FIX
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'UTS Mobile',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme, // ✅ FIX
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const MainWrapper(),
      },
    );
  }
}