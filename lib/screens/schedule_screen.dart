import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_schedule.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/schedule_card.dart';
import '../widgets/quick_note_dialog.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayFilter = 0; // 0 = All, 1 = Mon, ... 7 = Sun

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredSchedules = _selectedDayFilter == 0
        ? scheduleProvider.schedules
        : scheduleProvider.schedules
            .where((s) => s.daysOfWeek.contains(_selectedDayFilter))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Study Schedules & Alarms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Study Schedule',
            onPressed: () => _showAddEditScheduleDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Day filter bar
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildDayFilterChip('All Days', 0),
                _buildDayFilterChip('Mon', 1),
                _buildDayFilterChip('Tue', 2),
                _buildDayFilterChip('Wed', 3),
                _buildDayFilterChip('Thu', 4),
                _buildDayFilterChip('Fri', 5),
                _buildDayFilterChip('Sat', 6),
                _buildDayFilterChip('Sun', 7),
              ],
            ),
          ),
          const Divider(height: 1),

          // Schedules List
          Expanded(
            child: filteredSchedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 54, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 12),
                        Text(
                          'No study schedules found.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddEditScheduleDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Study Schedule'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSchedules.length,
                    itemCount: filteredSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = filteredSchedules[index];
                      return ScheduleCard(
                        schedule: schedule,
                        onEdit: () => _showAddEditScheduleDialog(
                            context, schedule: schedule),
                        onAddNote: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => QuickNoteDialog(
                              scheduleId: schedule.id,
                              defaultSubjectId: schedule.subjectId,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditScheduleDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New Schedule'),
      ),
    );
  }

  Widget _buildDayFilterChip(String label, int dayIndex) {
    final isSelected = _selectedDayFilter == dayIndex;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedDayFilter = dayIndex;
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _showAddEditScheduleDialog(BuildContext context,
      {StudySchedule? schedule}) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final isEditing = schedule != null;

    final titleController =
        TextEditingController(text: schedule?.title ?? '');
    final descController =
        TextEditingController(text: schedule?.description ?? '');

    String selectedSubjectId = schedule?.subjectId ??
        (scheduleProvider.subjects.isNotEmpty
            ? scheduleProvider.subjects.first.id
            : 'sub_1');

    TimeOfDay startTime =
        schedule?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime =
        schedule?.endTime ?? const TimeOfDay(hour: 10, minute: 30);
    List<int> selectedDays = schedule?.daysOfWeek != null
        ? List<int>.from(schedule!.daysOfWeek)
        : [1, 2, 3, 4, 5];
    int reminderMins = schedule?.reminderMinutesBefore ?? 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Study Schedule' : 'New Study Schedule',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () {
                            scheduleProvider.deleteSchedule(schedule.id);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subject dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: scheduleProvider.subjects.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(s.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedSubjectId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Schedule Title',
                      hintText: 'e.g. Physics Problem Solving',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Notes / Focus Area (Optional)',
                      hintText: 'e.g. Chapter 4 Thermodynamics',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Start Time',
                              style: TextStyle(fontSize: 12)),
                          subtitle: Text(
                            StudyDateUtils.formatTimeOfDay(startTime),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null) {
                              setModalState(() => startTime = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('End Time',
                              style: TextStyle(fontSize: 12)),
                          subtitle: Text(
                            StudyDateUtils.formatTimeOfDay(endTime),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null) {
                              setModalState(() => endTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Days Selection
                  const Text(
                    'Repeats on Days:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(7, (idx) {
                      final dayNum = idx + 1;
                      final isSelected = selectedDays.contains(dayNum);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                if (selectedDays.length > 1) {
                                  selectedDays.remove(dayNum);
                                }
                              } else {
                                selectedDays.add(dayNum);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              StudyDateUtils.getDayName(dayNum),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Reminder selector
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      const Text('Notify me:'),
                      const Spacer(),
                      DropdownButton<int>(
                        value: reminderMins,
                        items: const [
                          DropdownMenuItem(
                              value: 0, child: Text('At study time')),
                          DropdownMenuItem(
                              value: 5, child: Text('5 minutes before')),
                          DropdownMenuItem(
                              value: 10, child: Text('10 minutes before')),
                          DropdownMenuItem(
                              value: 15, child: Text('15 minutes before')),
                          DropdownMenuItem(
                              value: 30, child: Text('30 minutes before')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => reminderMins = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;

                        if (isEditing) {
                          await scheduleProvider.updateSchedule(
                            schedule.copyWith(
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              subjectId: selectedSubjectId,
                              startTime: startTime,
                              endTime: endTime,
                              daysOfWeek: selectedDays,
                              reminderMinutesBefore: reminderMins,
                            ),
                          );
                        } else {
                          await scheduleProvider.addSchedule(
                            subjectId: selectedSubjectId,
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            startTime: startTime,
                            endTime: endTime,
                            daysOfWeek: selectedDays,
                            reminderMinutesBefore: reminderMins,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Create Schedule',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
