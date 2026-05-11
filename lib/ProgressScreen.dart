import 'package:flutter/material.dart';

import 'package:gym_peak/workout_storage.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.onWorkoutsChanged});

  /// Called after a workout is deleted so parent can refresh other tabs (e.g. profile stats).
  final VoidCallback? onWorkoutsChanged;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const Color bgColor = Color(0xFF050B14);
  static const Color mint = Color(0xFF8ED8C3);

  Future<List<WorkoutEntry>>? _future;
  String? _deleteError;

  @override
  void initState() {
    super.initState();
    _future = WorkoutStorage.getAll();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Groups by normalized type, sorts each group by date ascending, returns map type -> sorted list
  Map<String, List<WorkoutEntry>> _groupByType(List<WorkoutEntry> all) {
    final map = <String, List<WorkoutEntry>>{};
    for (final w in all) {
      final key = w.type.trim().toLowerCase();
      map.putIfAbsent(key, () => []).add(w);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }
    return map;
  }

  String _displayType(List<WorkoutEntry> group) {
    if (group.isEmpty) return '';
    return group.first.type.trim();
  }

  Future<void> _confirmDelete(WorkoutEntry w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1524),
        title: const Text('Delete workout?', style: TextStyle(color: Colors.white)),
        content: Text(
          '${w.type.trim()} · ${_formatDate(w.date)}',
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: mint.withOpacity(0.9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await WorkoutStorage.deleteById(w.id);
      widget.onWorkoutsChanged?.call();
      setState(() {
        _deleteError = null;
        _future = WorkoutStorage.getAll();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleteError = 'Could not delete workout: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: mint));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load data', style: TextStyle(color: mint.withOpacity(0.9))),
          );
        }

        final all = snapshot.data ?? [];
        if (all.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(color: mint, fontSize: 32, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log workouts from the Track tab. You will see reps and weight changes over time for each exercise.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15),
                ),
              ],
            ),
          );
        }

        final grouped = _groupByType(all);

        return RefreshIndicator(
          color: mint,
          backgroundColor: bgColor,
          onRefresh: () async {
            setState(() {
              _future = WorkoutStorage.getAll();
            });
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              const Text(
                'Progress',
                style: TextStyle(color: mint, fontSize: 32, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_deleteError != null) ...[
                Text(
                  _deleteError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Compare each session to the one before for the same workout type.',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
              ),
              const SizedBox(height: 20),
              ...grouped.entries.map((e) {
                final list = e.value;
                final title = _displayType(list);
                return Card(
                  color: const Color(0xFF0D1524),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    iconColor: mint,
                    collapsedIconColor: mint,
                    title: Text(
                      title,
                      style: const TextStyle(color: mint, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${list.length} session${list.length == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                    children: [
                      ...List.generate(list.length, (i) {
                        final w = list[i];
                        WorkoutEntry? prev;
                        if (i > 0) prev = list[i - 1];

                        String deltaLine = 'First log for this exercise';
                        if (prev != null) {
                          final dr = w.reps - prev.reps;
                          final dw = w.weight - prev.weight;
                          final repPart = dr == 0
                              ? 'Reps unchanged'
                              : (dr > 0 ? '+$dr reps' : '$dr reps');
                          final weightPart = dw == 0
                              ? 'weight unchanged'
                              : (dw > 0 ? '+${dw.toStringAsFixed(1)} weight' : '${dw.toStringAsFixed(1)} weight');
                          deltaLine = '$repPart · $weightPart vs previous';
                        }

                        final improved = prev != null && (w.reps > prev.reps || w.weight > prev.weight);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          title: Text(
                            '${_formatDate(w.date)} · ${w.reps} reps · ${w.weight % 1 == 0 ? w.weight.toStringAsFixed(0) : w.weight.toStringAsFixed(1)} weight',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              deltaLine,
                              style: TextStyle(
                                color: improved ? mint : Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: Colors.redAccent.withOpacity(0.85),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(w),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
