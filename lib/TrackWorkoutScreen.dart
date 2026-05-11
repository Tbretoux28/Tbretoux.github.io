import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:gym_peak/workout_storage.dart';

class TrackWorkoutScreen extends StatefulWidget {
  const TrackWorkoutScreen({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<TrackWorkoutScreen> createState() => _TrackWorkoutScreenState();
}

class _TrackWorkoutScreenState extends State<TrackWorkoutScreen> {
  final _typeController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const Color bgColor = Color(0xFF050B14);
  static const Color mint = Color(0xFF8ED8C3);
  static const Color inputColor = Color(0xFFD9D9D9);
  bool _saving = false;

  @override
  void dispose() {
    _typeController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final reps = int.parse(_repsController.text.trim());
    final weight = double.parse(_weightController.text.trim());
    setState(() => _saving = true);
    try {
      // Keep IDs within 32-bit integer range so they work with older MySQL INT schemas.
      final safeId = ((DateTime.now().microsecondsSinceEpoch % 2000000000) +
              Random().nextInt(999))
          .toString();
      await WorkoutStorage.add(
        WorkoutEntry(
          id: safeId,
          type: _typeController.text.trim(),
          reps: reps,
          weight: weight,
          date: DateTime.now(),
        ),
      );

      widget.onSaved();
      if (!mounted) return;

      _typeController.clear();
      _repsController.clear();
      _weightController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved'),
          backgroundColor: mint,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save workout: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track workout',
              style: TextStyle(
                color: mint,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log type, reps, and weight after each session.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _typeController,
              style: const TextStyle(color: Colors.black87),
              decoration: _fieldDecoration('Type of workout (e.g. Bench press)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a workout type';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.black87),
              decoration: _fieldDecoration('Reps'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter reps';
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) return 'Enter a valid rep count';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.black87),
              decoration: _fieldDecoration('Weight (lb or kg)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter weight';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid weight';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mint,
                  foregroundColor: bgColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _saving ? 'Saving...' : 'Save workout',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: inputColor,
      border: const OutlineInputBorder(),
    );
  }
}
