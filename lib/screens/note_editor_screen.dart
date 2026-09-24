import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/study_note.dart';
import '../providers/notes_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_colors.dart';

class NoteEditorScreen extends StatefulWidget {
  final StudyNote? existingNote;
  final String? defaultScheduleId;
  final String? defaultSubjectId;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    this.defaultScheduleId,
    this.defaultSubjectId,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _checklistItemController;
  late TextEditingController _tagController;

  late TabController _tabController;
  late String _selectedSubjectId;
  String? _selectedScheduleId;
  List<ChecklistItem> _checklist = [];
  List<String> _tags = [];

  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    final scheduleProvider = context.read<ScheduleProvider>();

    _titleController =
        TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController =
        TextEditingController(text: widget.existingNote?.contentMarkdown ?? '');
    _checklistItemController = TextEditingController();
    _tagController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);

    _selectedSubjectId = widget.existingNote?.subjectId ??
        widget.defaultSubjectId ??
        (scheduleProvider.subjects.isNotEmpty
            ? scheduleProvider.subjects.first.id
            : 'sub_1');

    _selectedScheduleId =
        widget.existingNote?.scheduleId ?? widget.defaultScheduleId;

    if (widget.existingNote != null) {
      _checklist = List<ChecklistItem>.from(widget.existingNote!.checklist);
      _tags = List<String>.from(widget.existingNote!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _checklistItemController.dispose();
    _tagController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final text = _checklistItemController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklist.add(
          ChecklistItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: text,
            isDone: false,
          ),
        );
        _checklistItemController.clear();
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().replaceAll('#', '');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final notesProvider = context.read<NotesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingNote == null ? 'New Study Note' : 'Edit Note',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _isPreviewMode ? Icons.edit_note : Icons.visibility_outlined),
            tooltip: _isPreviewMode ? 'Edit Mode' : 'Markdown Preview',
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Note',
            onPressed: _saveNote,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Note Content'),
            Tab(text: 'Checklist & Meta'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Title & Markdown Content / Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Note Title / Topic Name...',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _isPreviewMode
                      ? Markdown(
                          data: _contentController.text.isEmpty
                              ? '*No markdown content entered yet.*'
                              : _contentController.text,
                        )
                      : TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            hintText:
                                'Write your study notes, code blocks, bullet points...\n\n# Markdown Tips:\n- Use **bold** or *italic*\n- Use # for Headings\n- Use `code` blocks\n- Use - for bullet lists',
                            border: InputBorder.none,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Tab 2: Checklist & Metadata
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Subject Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                const SizedBox(height: 16),

                // Link to Schedule (Optional)
                DropdownButtonFormField<String?>(
                  value: _selectedScheduleId,
                  decoration: InputDecoration(
                    labelText: 'Linked Schedule (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (General Note)'),
                    ),
                    ...scheduleProvider.schedules.map((s) {
                      return DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.title),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedScheduleId = val);
                  },
                ),
                const SizedBox(height: 24),

                // Checklist Section
                const Text(
                  'Topics & Concepts Studied (Checklist):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _checklistItemController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Mastered page 45 proof',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (_) => _addChecklistItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: _addChecklistItem,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_checklist.isEmpty)
                  Text(
                    'No checklist items added yet.',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 13,
                    ),
                  )
                else
                  ..._checklist.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Checkbox(
                          value: item.isDone,
                          onChanged: (val) {
                            setState(() {
                              item.isDone = val ?? false;
                            });
                          },
                        ),
                        title: Text(
                          item.text,
                          style: TextStyle(
                            decoration: item.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () {
                            setState(() {
                              _checklist.removeAt(idx);
                            });
                          },
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Tags Section
                const Text(
                  'Tags:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'Add a tag (e.g. calculus, exam1)...',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    final notesProvider = context.read<NotesProvider>();
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Study Note'
        : _titleController.text.trim();

    if (widget.existingNote != null) {
      await notesProvider.updateNote(
        widget.existingNote!.copyWith(
          title: title,
          contentMarkdown: _contentController.text,
          subjectId: _selectedSubjectId,
          scheduleId: _selectedScheduleId,
          checklist: _checklist,
          tags: _tags,
        ),
      );
    } else {
      await notesProvider.createNote(
        subjectId: _selectedSubjectId,
        scheduleId: _selectedScheduleId,
        title: title,
        contentMarkdown: _contentController.text,
        checklist: _checklist,
        tags: _tags,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
