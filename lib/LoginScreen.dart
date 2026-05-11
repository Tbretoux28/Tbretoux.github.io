import 'package:flutter/material.dart';

import 'package:gym_peak/login_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await LoginRepository.authenticate(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF050B14);
    const Color mint = Color(0xFF8ED8C3);
    const Color inputColor = Color(0xFFD9D9D9);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Gym Peak',
                style: TextStyle(
                  color: mint,
                  fontSize: 42,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  fillColor: inputColor,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: inputColor,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.check_box_outline_blank, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Remember Me',
                    style: TextStyle(color: mint),
                  ),
                  Spacer(),
                  Text(
                    'Forgot Password',
                    style: TextStyle(color: mint),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pushNamed('/create-account'),
                  child: const Text(
                    "Don't have an account? Create an account",
                    style: TextStyle(color: mint),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mint,
                    foregroundColor: bgColor,
                  ),
                  child: Text(_isSubmitting ? 'Logging in...' : 'Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}