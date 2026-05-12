import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your files - check these paths match your project
import 'firebase_options.dart'; 
import 'screens/onboarding.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/todo.dart';
import 'screens/completed.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Wrap app in ProviderScope for Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Watch the Auth State
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Dump',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      
      // 4. Decision logic for the landing page
      home: authState.when(
        data: (user) {
          // If logged in and verified, go to TodoPage
          if (user != null && user.emailVerified) {
            return const TodoPage();
          }
          // Otherwise, start with Onboarding
          return const OnboardingPage();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Connection Error: $err')),
        ),
      ),

      // 5. Named routes for manual navigation
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const TodoPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/completed': (context) => const CompletedTasksPage()
      },
    );
  }
}
