import 'package:flutter/material.dart';

import 'package:gym_peak/profile_storage.dart';
import 'package:gym_peak/workout_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color bgColor = Color(0xFF050B14);
  static const Color mint = Color(0xFF8ED8C3);
  static const Color cardColor = Color(0xFF0D1524);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _goalController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  UserProfile? _profile;
  int _workoutCount = 0;
  bool _loading = true;
  String? _error;
  String _preferredUnit = 'lb';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _goalController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ProfileStorage.load();
      final workouts = await WorkoutStorage.getAll();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.displayName;
        _emailController.text = profile.email;
        _goalController.text = profile.fitnessGoal;
        _heightController.text = profile.height;
        _weightController.text = profile.weight;
        _preferredUnit = profile.preferredUnit;
        _workoutCount = workouts.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load profile data: $e';
      });
    }
  }

  Future<void> _saveProfile() async {
    final existing = _profile ?? await ProfileStorage.load();
    await ProfileStorage.save(
      existing.copyWith(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        fitnessGoal: _goalController.text.trim(),
        height: _heightController.text.trim(),
        weight: _weightController.text.trim(),
        preferredUnit: _preferredUnit,
      ),
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved'),
        backgroundColor: mint,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
  }

  String? _memberSinceLabel() {
    final iso = _profile?.memberSinceIso;
    if (iso == null) return null;
    final d = DateTime.tryParse(iso);
    if (d == null) return null;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _toggleUnit(bool useKg) {
    final nextUnit = useKg ? 'kg' : 'lb';
    final text = _weightController.text.trim();
    final n = double.tryParse(text);
    setState(() {
      if (n != null && _preferredUnit != nextUnit) {
        final converted = nextUnit == 'kg' ? n * 0.45359237 : n / 0.45359237;
        _weightController.text = converted.toStringAsFixed(1);
      }
      _preferredUnit = nextUnit;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: mint));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mint,
                  foregroundColor: bgColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        const Text(
          'Profile',
          style: TextStyle(color: mint, fontSize: 32, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: mint,
                  child: Text(
                    _initials(_nameController.text),
                    style: const TextStyle(
                      color: bgColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty ? 'Your name' : _nameController.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_emailController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _emailController.text,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
                      if (_memberSinceLabel() != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Member since ${_memberSinceLabel()}',
                          style: TextStyle(color: mint.withOpacity(0.9), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your details',
                  style: TextStyle(color: mint, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Display name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Fitness goal (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Height (e.g. 5\'10" or 178 cm)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Weight ($_preferredUnit)'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      foregroundColor: bgColor,
                    ),
                    child: const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: cardColor,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.fitness_center_rounded, color: mint.withOpacity(0.9)),
                title: const Text('Workouts logged', style: TextStyle(color: Colors.white)),
                trailing: Text(
                  '$_workoutCount',
                  style: const TextStyle(color: mint, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Settings',
                  style: TextStyle(color: mint, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: Icon(Icons.straighten_rounded, color: Colors.white54),
                title: const Text('Units', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _preferredUnit == 'kg'
                      ? 'Metric (kg)'
                      : 'Imperial (lb)',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                trailing: Switch(
                  value: _preferredUnit == 'kg',
                  onChanged: _toggleUnit,
                  activeColor: mint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
          icon: const Icon(Icons.logout_rounded, color: mint),
          label: const Text('Log out', style: TextStyle(color: mint)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: mint),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: mint.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: mint.withOpacity(0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: mint),
      ),
    );
  }
}
