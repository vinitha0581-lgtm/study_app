import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_note.dart';
import '../providers/notes_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_colors.dart';

class QuickNoteDialog extends StatefulWidget {
  final String? scheduleId;
  final String? defaultSubjectId;

  const QuickNoteDialog({
    super.key,
    this.scheduleId,
    this.defaultSubjectId,
  });

  @override
  State<QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<QuickNoteDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _checklistInputController = TextEditingController();

  late String _selectedSubjectId;
  final List<ChecklistItem> _checklistItems = [];

  @override
  void initState() {
    super.initState();
    final scheduleProvider = context.read<ScheduleProvider>();
    _selectedSubjectId = widget.defaultSubjectId ??
        (scheduleProvider.subjects.isNotEmpty
            ? scheduleProvider.subjects.first.id
            : 'sub_1');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _checklistInputController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add(
          ChecklistItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: text,
            isDone: false,
          ),
        );
        _checklistInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final notesProvider = context.read<NotesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Study Note & Checklist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: scheduleProvider.subjects.map((sub) {
                return DropdownMenuItem(
                  value: sub.id,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(sub.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(sub.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubjectId = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Session Topic / Title',
                hintText: 'e.g. Dynamic Programming Memoization',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            // Markdown / Notes text
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'What did you study? (Markdown supported)',
                        hintText:
                            'Write key formulas, concepts, or questions...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Checklist / Topics Covered:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Add Checklist item row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _checklistInputController,
                            decoration: InputDecoration(
                              hintText: 'Add a topic item...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onSubmitted: (_) => _addChecklistItem(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addChecklistItem,
                          icon: const Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Checklist items
                    ..._checklistItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Row(
                        children: [
                          Checkbox(
                            value: item.isDone,
                            onChanged: (val) {
                              setState(() {
                                item.isDone = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                decoration: item.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _checklistItems.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty &&
                        _contentController.text.trim().isEmpty &&
                        _checklistItems.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }
                    await notesProvider.createNote(
                      subjectId: _selectedSubjectId,
                      scheduleId: widget.scheduleId,
                      title: _titleController.text.trim().isEmpty
                          ? 'Study Session Note'
                          : _titleController.text.trim(),
                      contentMarkdown: _contentController.text.trim(),
                      checklist: _checklistItems,
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
