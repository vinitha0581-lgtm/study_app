import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../providers/session_provider.dart';

class CircularProgressTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final PomodoroPhase phase;
  final TimerMode mode;
  final int elapsedStopwatchSeconds;
  final bool isRunning;

  const CircularProgressTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.phase,
    required this.mode,
    required this.elapsedStopwatchSeconds,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalSeconds > 0
        ? (1.0 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    Color ringColor;
    String phaseLabel;
    IconData phaseIcon;

    switch (phase) {
      case PomodoroPhase.work:
        ringColor = AppColors.primary;
        phaseLabel = 'FOCUS SESSION';
        phaseIcon = Icons.psychology;
        break;
      case PomodoroPhase.shortBreak:
        ringColor = AppColors.secondary;
        phaseLabel = 'SHORT BREAK';
        phaseIcon = Icons.coffee;
        break;
      case PomodoroPhase.longBreak:
        ringColor = AppColors.success;
        phaseLabel = 'LONG BREAK';
        phaseIcon = Icons.self_improvement;
        break;
    }

    final displayText = mode == TimerMode.stopwatch
        ? StudyDateUtils.formatSeconds(elapsedStopwatchSeconds)
        : StudyDateUtils.formatSeconds(remainingSeconds);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(isRunning ? 0.25 : 0.05),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Circular Progress Track
          SizedBox(
            width: 250,
            height: 250,
            child: CircularProgressIndicator(
              value: mode == TimerMode.stopwatch ? 1.0 : (1.0 - progress),
              strokeWidth: 12,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Inner Info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(phaseIcon, size: 16, color: ringColor),
                  const SizedBox(width: 6),
                  Text(
                    phaseLabel,
                    style: TextStyle(
                      color: ringColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayText,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRunning ? 'Timer Active' : 'Ready',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
