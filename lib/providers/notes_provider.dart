import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/study_note.dart';
import '../services/storage_service.dart';

class NotesProvider with ChangeNotifier {
  final StorageService _storageService;
  final _uuid = const Uuid();

  List<StudyNote> _notes = [];
  String _searchQuery = '';
  String? _selectedSubjectFilter;

  NotesProvider(this._storageService) {
    loadNotes();
  }

  List<StudyNote> get allNotes => _notes;
  String get searchQuery => _searchQuery;
  String? get selectedSubjectFilter => _selectedSubjectFilter;

  List<StudyNote> get filteredNotes {
    return _notes.where((n) {
      final matchesSearch = _searchQuery.isEmpty ||
          n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.contentMarkdown.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          n.checklist.any((c) => c.text.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesSubject = _selectedSubjectFilter == null ||
          n.subjectId == _selectedSubjectFilter;

      return matchesSearch && matchesSubject;
    }).toList();
  }

  void loadNotes() {
    _notes = _storageService.getNotes();
    // Default seed note if empty
    if (_notes.isEmpty) {
      _notes = [
        StudyNote(
          id: 'note_demo_1',
          subjectId: 'sub_2',
          title: 'Graph Traversal & BFS vs DFS Summary',
          contentMarkdown: '''
### Key Takeaways
- **BFS (Breadth-First Search)**: Uses a Queue (FIFO). Ideal for finding shortest path in unweighted graphs.
- **DFS (Depth-First Search)**: Uses a Stack / Recursion (LIFO). Ideal for cycle detection, topological sorting, connected components.

```dart
void bfs(Node start) {
  final queue = <Node>[start];
  final visited = <Node>{start};
  while (queue.isNotEmpty) {
    var curr = queue.removeAt(0);
    for (var neighbor in curr.neighbors) {
      if (!visited.contains(neighbor)) {
        visited.add(neighbor);
        queue.add(neighbor);
      }
    }
  }
}
```
''',
          checklist: [
            ChecklistItem(id: 'c1', text: 'Implement BFS algorithm in Dart', isDone: true),
            ChecklistItem(id: 'c2', text: 'Solve LeetCode #200 (Number of Islands)', isDone: true),
            ChecklistItem(id: 'c3', text: 'Practice Dijkstra algorithm tomorrow', isDone: false),
          ],
          tags: ['algorithms', 'graphs', 'interview-prep'],
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];
      _storageService.saveNotes(_notes);
    }
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSubjectFilter(String? subjectId) {
    _selectedSubjectFilter = subjectId;
    notifyListeners();
  }

  List<StudyNote> getNotesForSchedule(String scheduleId) {
    return _notes.where((n) => n.scheduleId == scheduleId).toList();
  }

  List<StudyNote> getNotesForSubject(String subjectId) {
    return _notes.where((n) => n.subjectId == subjectId).toList();
  }

  Future<StudyNote> createNote({
    required String subjectId,
    required String title,
    required String contentMarkdown,
    String? scheduleId,
    String? sessionId,
    List<ChecklistItem>? checklist,
    List<String>? tags,
  }) async {
    final note = StudyNote(
      id: _uuid.v4(),
      subjectId: subjectId,
      scheduleId: scheduleId,
      sessionId: sessionId,
      title: title.isEmpty ? 'Untitled Study Note' : title,
      contentMarkdown: contentMarkdown,
      checklist: checklist ?? [],
      tags: tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _notes.insert(0, note);
    await _storageService.saveNotes(_notes);
    notifyListeners();
    return note;
  }

  Future<void> updateNote(StudyNote updated) async {
    final index = _notes.indexWhere((n) => n.id == updated.id);
    if (index != -1) {
      _notes[index] = updated.copyWith(updatedAt: DateTime.now());
      await _storageService.saveNotes(_notes);
      notifyListeners();
    }
  }

  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex != -1) {
      final note = _notes[noteIndex];
      final itemIndex = note.checklist.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        final item = note.checklist[itemIndex];
        note.checklist[itemIndex] = item.copyWith(isDone: !item.isDone);
        await _storageService.saveNotes(_notes);
        notifyListeners();
      }
    }
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }
}
