import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health_app/src/routing/app_router.dart';
import 'package:health_app/src/services/supabase_client.dart';
import 'package:health_app/src/services/hive_service.dart';
import 'package:health_app/src/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional - will use defaults if not found)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file not found, use defaults
    print('Warning: .env file not found, using defaults');
  }

  // Initialize Supabase client
  await SupabaseService.initialize();

  // Initialize Hive for offline storage
  await HiveService.initialize();

  // Set system UI overlay style for dark mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: HealthApp(),
    ),
  );
}

class HealthApp extends ConsumerWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Health Data Aggregator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      routerConfig: router,
    );
  }
}

