import 'package:flutter/material.dart';
import 'package:gym_peak/CreateAccountScreen.dart';
import 'package:gym_peak/LoginScreen.dart';
import 'package:gym_peak/HomeScreen.dart';

void main() {
  runApp(const GymPeakApp());
}

class GymPeakApp extends StatelessWidget {
  const GymPeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Peak',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF050B14),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/create-account': (context) => const CreateAccountScreen(),
        '/home': (context) => const HomeScreen(),
      },
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            // Keep normal full-screen UI on phones; frame it on larger screens.
            if (constraints.maxWidth < 600) return child;

            return ColoredBox(
              color: const Color(0xFF02060D),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    width: 390,
                    height: 844,
                    decoration: BoxDecoration(
                      color: const Color(0xFF050B14),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}