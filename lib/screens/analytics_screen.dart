import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/notes_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todayMins = sessionProvider.todayStudyMinutes;
    final weekMins = sessionProvider.thisWeekStudyMinutes;
    final totalSessions = sessionProvider.sessions.length;
    final totalNotes = notesProvider.allNotes.length;
    final streak = sessionProvider.currentStreakDays;
    final subjectMins = sessionProvider.getMinutesPerSubject();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Analytics & Progress',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat Grid Cards
            Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Today\'s Time',
                  value: StudyDateUtils.formatDuration(todayMins),
                  icon: Icons.today,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  title: 'This Week',
                  value: StudyDateUtils.formatDuration(weekMins),
                  icon: Icons.date_range,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Study Streak',
                  value: '$streak Days',
                  icon: Icons.local_fire_department,
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  title: 'Notes Created',
                  value: '$totalNotes Notes',
                  icon: Icons.edit_note,
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Subject Breakdown Section
            const Text(
              'Time Spent Per Subject',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (scheduleProvider.subjects.isEmpty)
              const Text('No subjects added.')
            else
              ...scheduleProvider.subjects.map((sub) {
                final mins = subjectMins[sub.id] ?? 0;
                final color = Color(sub.colorValue);
                final targetWeeklyMins = sub.targetMinutesPerWeek;
                final fraction = targetWeeklyMins > 0
                    ? (mins / targetWeeklyMins).clamp(0.0, 1.0)
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sub.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            StudyDateUtils.formatDuration(mins),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          backgroundColor:
                              Theme.of(context).dividerColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Weekly Target: ${StudyDateUtils.formatDuration(targetWeeklyMins)} (${(fraction * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Study Session History Log
            const Text(
              'Recent Study Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (sessionProvider.sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No completed study sessions yet.\nStart the timer to log your first session!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ),
              )
            else
              ...sessionProvider.sessions.take(5).map((session) {
                final sub = scheduleProvider.getSubjectById(session.subjectId);
                final subColor =
                    sub != null ? Color(sub.colorValue) : AppColors.primary;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: subColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.check_circle_outline,
                            color: subColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub?.name ?? 'Study Session',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              StudyDateUtils.shortDateFormat
                                  .format(session.startTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${session.durationMinutes}m',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
