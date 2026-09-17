import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mock/mock_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'package:window_manager/window_manager.dart';
import 'services/backend_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Automatically activate the Python AI backend server if not running
  unawaited(BackendLauncher.ensureBackendRunning());

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(1024, 640),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'EventGuard AI',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Intercept window close to gracefully terminate Python backend
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockState()),
      ],
      child: const EventGuardApp(),
    ),
  );
}

class EventGuardApp extends StatefulWidget {
  const EventGuardApp({Key? key}) : super(key: key);

  @override
  State<EventGuardApp> createState() => _EventGuardAppState();
}

class _EventGuardAppState extends State<EventGuardApp> with WindowListener, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    debugPrint('[APP] Window close requested. Shutting down Python backend and releasing camera...');
    await BackendLauncher.shutdownBackend();
    await windowManager.destroy();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      BackendLauncher.shutdownBackend();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainLayout(),
      },
    );
  }
}
