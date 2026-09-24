import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_schedule.dart';
import '../providers/schedule_provider.dart';
import '../providers/session_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import 'subject_badge.dart';

class ScheduleCard extends StatelessWidget {
  final StudySchedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onAddNote;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.onEdit,
    this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final subject = scheduleProvider.getSubjectById(schedule.subjectId);
    final subjectColor = subject != null ? Color(subject.colorValue) : AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: schedule.isEnabled
              ? subjectColor.withOpacity(0.3)
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with color strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: subjectColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SubjectBadge(subject: subject, isSmall: true),
                  const Spacer(),
                  // Reminder tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            size: 13,
                            color: schedule.isEnabled
                                ? AppColors.warning
                                : Theme.of(context).disabledColor),
                        const SizedBox(width: 4),
                        Text(
                          '${schedule.reminderMinutesBefore}m before',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: schedule.isEnabled
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: schedule.isEnabled,
                    activeColor: subjectColor,
                    onChanged: (val) {
                      scheduleProvider.toggleSchedule(schedule.id);
                    },
                  ),
                ],
              ),
            ),
            // Body Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (schedule.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      schedule.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Time & Duration Row
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded,
                          size: 16, color: subjectColor),
                      const SizedBox(width: 6),
                      Text(
                        '${StudyDateUtils.formatTimeOfDay(schedule.startTime)} - ${StudyDateUtils.formatTimeOfDay(schedule.endTime)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${StudyDateUtils.formatDuration(schedule.durationMinutes)})',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Days of week pills
                  Row(
                    children: List.generate(7, (idx) {
                      final dayNum = idx + 1;
                      final isSelected = schedule.daysOfWeek.contains(dayNum);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? subjectColor.withOpacity(0.2)
                                : Theme.of(context).dividerColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? subjectColor.withOpacity(0.6)
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            StudyDateUtils.getDayName(dayNum).substring(0, 1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? subjectColor
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  // Actions Row
                  Row(
                    children: [
                      // Start Study Session button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final sessionProvider =
                                context.read<SessionProvider>();
                            sessionProvider.setupCustomCountdown(
                              subjectId: schedule.subjectId,
                              scheduleId: schedule.id,
                              minutes: schedule.durationMinutes,
                            );
                            sessionProvider.startTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Started study session for "${schedule.title}"'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Start Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: subjectColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Note button
                      OutlinedButton.icon(
                        onPressed: onAddNote,
                        icon: const Icon(Icons.note_add_outlined, size: 16),
                        label: const Text('Note'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: onEdit,
                        tooltip: 'Edit Schedule',
                      ),
                    ],
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
