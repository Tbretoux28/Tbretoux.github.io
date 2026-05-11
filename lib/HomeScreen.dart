import 'package:flutter/material.dart';

import 'package:gym_peak/ProfileScreen.dart';
import 'package:gym_peak/ProgressScreen.dart';
import 'package:gym_peak/TrackWorkoutScreen.dart';
import 'package:gym_peak/login_repository.dart';
import 'package:gym_peak/workout_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _progressRefreshKey = 0;
  int _profileStatsKey = 0;
  int _homeDataKey = 0;

  static const Color bgColor = Color(0xFF050B14);
  static const Color mint = Color(0xFF8ED8C3);
  static const Color cardColor = Color(0xFF0D1524);
  static const Color mutedText = Color(0xFFAAB5C5);

  Widget _buildHomeContent() {
    return FutureBuilder<List<WorkoutEntry>>(
      key: ValueKey(_homeDataKey),
      future: WorkoutStorage.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: mint));
        }

        final workouts = snapshot.data ?? [];
        final sorted = [...workouts]..sort((a, b) => b.date.compareTo(a.date));
        final latest = sorted.isNotEmpty ? sorted.first : null;
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final thisWeek = workouts.where((w) => !w.date.isBefore(weekStart)).toList();

        return FutureBuilder<String>(
          future: LoginRepository.currentUsername(),
          builder: (context, userSnapshot) {
            final username = userSnapshot.data ?? 'athlete';

            return RefreshIndicator(
              color: mint,
              backgroundColor: bgColor,
              onRefresh: () async {
                setState(() => _homeDataKey++);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                children: [
                  Text(
                    'Good to see you, $username',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Track your next session and keep improving.',
                    style: TextStyle(color: mutedText, fontSize: 15),
                  ),
                  const SizedBox(height: 18),
                  _homeActionCard(
                    title: 'Track New Workout',
                    subtitle: 'Log type, reps, and weight',
                    icon: Icons.add_circle_outline_rounded,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  _homeActionCard(
                    title: 'View Progress',
                    subtitle: 'Compare reps and weight over time',
                    icon: Icons.trending_up_rounded,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'This week',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          label: 'Workouts',
                          value: '${thisWeek.length}',
                          icon: Icons.fitness_center_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Last workout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (latest == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'No workouts logged yet. Tap "Track New Workout" to start.',
                        style: TextStyle(color: mutedText, fontSize: 14),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest.type,
                            style: const TextStyle(
                              color: mint,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${latest.reps} reps • ${latest.weight.toStringAsFixed(latest.weight % 1 == 0 ? 0 : 1)} weight',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(latest.date),
                            style: const TextStyle(color: mutedText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _homeActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: mint.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: mint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: mutedText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: mint, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: mutedText, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(),
            TrackWorkoutScreen(
              onSaved: () => setState(() {
                _progressRefreshKey++;
                _profileStatsKey++;
                _homeDataKey++;
              }),
            ),
            ProgressScreen(
              key: ValueKey(_progressRefreshKey),
              onWorkoutsChanged: () => setState(() {
                _profileStatsKey++;
                _homeDataKey++;
              }),
            ),
            ProfileScreen(key: ValueKey(_profileStatsKey)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 'Home', 0),
                _navItem(Icons.add_circle_outline_rounded, 'Track', 1),
                _navItem(Icons.trending_up_rounded, 'Progress', 2),
                _navItem(Icons.person_rounded, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? mint : Colors.white54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? mint : Colors.white54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}