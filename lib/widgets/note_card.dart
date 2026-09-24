import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_note.dart';
import '../providers/schedule_provider.dart';
import '../providers/notes_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import 'subject_badge.dart';

class NoteCard extends StatelessWidget {
  final StudyNote note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final notesProvider = context.read<NotesProvider>();
    final subject = scheduleProvider.getSubjectById(note.subjectId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completedChecklist = note.checklist.where((c) => c.isDone).length;
    final totalChecklist = note.checklist.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Subject badge, timestamp & menu
            Row(
              children: [
                SubjectBadge(subject: subject, isSmall: true),
                const Spacer(),
                Text(
                  StudyDateUtils.shortDateFormat.format(note.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  onSelected: (val) {
                    if (val == 'delete') onDelete?.call();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (note.contentMarkdown.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.contentMarkdown.replaceAll(RegExp(r'#|\*|`'), '').trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
            ],
            // Checklist preview
            if (totalChecklist > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      completedChecklist == totalChecklist
                          ? Icons.check_circle
                          : Icons.checklist_rtl_rounded,
                      size: 16,
                      color: completedChecklist == totalChecklist
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$completedChecklist / $totalChecklist items studied',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalChecklist > 0
                              ? (completedChecklist / totalChecklist)
                              : 0.0,
                          backgroundColor:
                              Theme.of(context).dividerColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completedChecklist == totalChecklist
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Tags
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: note.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
