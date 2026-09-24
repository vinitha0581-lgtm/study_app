import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/note_card.dart';
import '../utils/app_colors.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredNotes = notesProvider.filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Notes & Checklists',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes, formulas, checklists...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: notesProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => notesProvider.setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                  ),
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              ),
              onChanged: (val) => notesProvider.setSearchQuery(val),
            ),
          ),

          // Subject category pills
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  context,
                  label: 'All Subjects',
                  isSelected: notesProvider.selectedSubjectFilter == null,
                  onTap: () => notesProvider.setSubjectFilter(null),
                ),
                ...scheduleProvider.subjects.map((sub) {
                  return _buildFilterChip(
                    context,
                    label: sub.name,
                    color: Color(sub.colorValue),
                    isSelected:
                        notesProvider.selectedSubjectFilter == sub.id,
                    onTap: () => notesProvider.setSubjectFilter(sub.id),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notes List
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 56, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 12),
                        Text(
                          'No study notes found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const NoteEditorScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Study Note'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return NoteCard(
                        note: note,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  NoteEditorScreen(existingNote: note),
                            ),
                          );
                        },
                        onDelete: () {
                          notesProvider.deleteNote(note.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => const NoteEditorScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: effectiveColor.withOpacity(0.2),
        checkmarkColor: effectiveColor,
        labelStyle: TextStyle(
          color: isSelected ? effectiveColor : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
