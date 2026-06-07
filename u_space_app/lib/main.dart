import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen_two.dart';
import 'screens/home_page.dart';
import 'screens/search_screen.dart';
import 'screens/profile_page.dart';
import 'screens/settings_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/student_timetable_screen.dart';
import 'screens/lecturer_courses_screen.dart';
import 'screens/admin_home_page.dart';
import 'screens/lecturer_home_page.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';


void main() {
  runApp(const ProviderScope(child: USpaceApp()));
}

class USpaceApp extends ConsumerWidget {
  const USpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(appTheme),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/search': (context) => const SearchScreen(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsScreen(),
        '/messages': (context) => const MessagesScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/timetable': (context) => const StudentTimetableScreen(),
        '/my-courses': (context) => const LecturerCoursesScreen(),
      },
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Show splash for at least 3 seconds
    final minDelay = Future.delayed(const Duration(seconds: 3));
    
    // Check auto login
    final authNotifier = ref.read(authStateProvider.notifier);
    final isLoggedIn = await authNotifier.checkAutoLogin();
    
    await minDelay;
    
    if (mounted) {
      if (isLoggedIn) {
        final role = ref.read(authStateProvider).value?.role ?? 'STUDENT';
        Widget home;
        switch (role) {
          case 'ADMIN':
            home = const AdminHomePage();
            break;
          case 'LECTURER':
            home = const LecturerHomePage();
            break;
          default:
            home = const HomePage();
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => home),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreenTwo()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets_splash/group_of_students.svg',
              height: 180,
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: GoogleFonts.lemon(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
                children: const [
                  TextSpan(
                    text: 'U ',
                    style: TextStyle(
                      color: Color(0xFF0011FF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextSpan(
                    text: '-',
                    style: TextStyle(
                      color: Color(0xFFFF0000),
                    ),
                  ),
                  TextSpan(
                    text: 'Space',
                    style: TextStyle(
                      color: Color(0xFFFF5100),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
