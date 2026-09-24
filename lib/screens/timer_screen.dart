import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/circular_progress_timer.dart';
import '../widgets/quick_note_dialog.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _customMinutes = 45;

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeSubject = sessionProvider.activeSubjectId != null
        ? scheduleProvider.getSubjectById(sessionProvider.activeSubjectId!)
        : (scheduleProvider.subjects.isNotEmpty
            ? scheduleProvider.subjects.first
            : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Timer & Focus',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Quick Study Note',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => QuickNoteDialog(
                  defaultSubjectId: activeSubject?.id,
                  scheduleId: sessionProvider.activeScheduleId,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // Mode Segmented Buttons
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        title: 'Pomodoro (25/5)',
                        icon: Icons.timer,
                        isSelected:
                            sessionProvider.mode == TimerMode.pomodoro,
                        onTap: () {
                          if (activeSubject != null) {
                            sessionProvider.setupPomodoro(
                              subjectId: activeSubject.id,
                            );
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildModeTab(
                        title: 'Custom Focus',
                        icon: Icons.hourglass_top,
                        isSelected:
                            sessionProvider.mode == TimerMode.customCountdown,
                        onTap: () {
                          if (activeSubject != null) {
                            sessionProvider.setupCustomCountdown(
                              subjectId: activeSubject.id,
                              minutes: _customMinutes,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subject selector chip row
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Focus Subject:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: scheduleProvider.subjects.length,
                  itemBuilder: (context, index) {
                    final sub = scheduleProvider.subjects[index];
                    final isSelected = activeSubject?.id == sub.id;
                    final color = Color(sub.colorValue);

                    return GestureDetector(
                      onTap: () {
                        if (sessionProvider.mode == TimerMode.pomodoro) {
                          sessionProvider.setupPomodoro(subjectId: sub.id);
                        } else {
                          sessionProvider.setupCustomCountdown(
                            subjectId: sub.id,
                            minutes: _customMinutes,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.2)
                              : Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sub.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? color : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Circular Timer Widget
              CircularProgressTimer(
                remainingSeconds: sessionProvider.remainingSeconds,
                totalSeconds: sessionProvider.totalSeconds,
                phase: sessionProvider.phase,
                mode: sessionProvider.mode,
                elapsedStopwatchSeconds:
                    sessionProvider.elapsedStopwatchSeconds,
                isRunning: sessionProvider.isRunning && !sessionProvider.isPaused,
              ),

              const SizedBox(height: 24),

              // Pomodoro Cycle Indicator
              if (sessionProvider.mode == TimerMode.pomodoro) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (idx) {
                    final isCompleted =
                        (sessionProvider.completedCycles % 4) > idx;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : Theme.of(context).dividerColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  '${sessionProvider.completedCycles} cycles finished today',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Custom time duration pills (when in custom countdown)
              if (sessionProvider.mode == TimerMode.customCountdown &&
                  !sessionProvider.isRunning) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [15, 30, 45, 60, 90].map((mins) {
                    final isSelected = _customMinutes == mins;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('${mins}m'),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _customMinutes = mins);
                            if (activeSubject != null) {
                              sessionProvider.setupCustomCountdown(
                                subjectId: activeSubject.id,
                                minutes: mins,
                              );
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Main Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset / Stop button
                  if (sessionProvider.isRunning || sessionProvider.isPaused) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        sessionProvider.stopTimer(saveSession: false);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Start / Pause button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (sessionProvider.isRunning &&
                          !sessionProvider.isPaused) {
                        sessionProvider.pauseTimer();
                      } else if (sessionProvider.isPaused) {
                        sessionProvider.resumeTimer();
                      } else {
                        if (activeSubject != null &&
                            sessionProvider.activeSubjectId == null) {
                          sessionProvider.setupPomodoro(
                              subjectId: activeSubject.id);
                        }
                        sessionProvider.startTimer();
                      }
                    },
                    icon: Icon(
                      sessionProvider.isRunning && !sessionProvider.isPaused
                          ? Icons.pause
                          : Icons.play_arrow_rounded,
                      size: 26,
                    ),
                    label: Text(
                      sessionProvider.isRunning && !sessionProvider.isPaused
                          ? 'Pause'
                          : (sessionProvider.isPaused ? 'Resume' : 'Start Focus'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  // Complete early button
                  if (sessionProvider.isRunning || sessionProvider.isPaused) ...[
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.check),
                      tooltip: 'Complete & Log Session',
                      onPressed: () {
                        sessionProvider.stopTimer(saveSession: true);
                        showDialog(
                          context: context,
                          builder: (ctx) => QuickNoteDialog(
                            defaultSubjectId: activeSubject?.id,
                            scheduleId: sessionProvider.activeScheduleId,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Theme.of(context).disabledColor,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
