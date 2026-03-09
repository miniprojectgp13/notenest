import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/todo_task.dart';
import '../../core/state/app_state.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dayTasks = appState.tasks
        .where((task) => _sameDay(task.dateTime, _selectedDate))
        .toList();

    final completed =
        dayTasks.where((task) => task.status == TaskStatus.completed).toList();
    final inProgress =
        dayTasks.where((task) => task.status == TaskStatus.inProgress).toList();
    final notCompleted = dayTasks
        .where((task) => task.status == TaskStatus.notCompleted)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 920;
          if (wide) {
            return Row(
              children: [
                SizedBox(width: 380, child: _calendarPane(context, dayTasks)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _statusPane(
                    context,
                    completed: completed,
                    inProgress: inProgress,
                    notCompleted: notCompleted,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _calendarPane(context, dayTasks),
              const Divider(height: 1),
              Expanded(
                child: _statusPane(
                  context,
                  completed: completed,
                  inProgress: inProgress,
                  notCompleted: notCompleted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _calendarPane(BuildContext context, List<TodoTask> dayTasks) {
    final appState = context.watch<AppState>();
    final completedCount =
        dayTasks.where((task) => task.status == TaskStatus.completed).length;
    final inProgressCount =
        dayTasks.where((task) => task.status == TaskStatus.inProgress).length;
    final notCompletedCount =
        dayTasks.where((task) => task.status == TaskStatus.notCompleted).length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F2FF), Color(0xFFF2F8FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Tracker',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _monthCalendar(appState.tasks),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              _LegendDot(color: Colors.green, label: 'Completed'),
              _LegendDot(color: Colors.amber, label: 'In Progress'),
              _LegendDot(color: Colors.redAccent, label: 'Not Completed'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniSummary('Done', completedCount, Colors.green),
              _miniSummary('Progress', inProgressCount, Colors.amber),
              _miniSummary('Pending', notCompletedCount, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPane(
    BuildContext context, {
    required List<TodoTask> completed,
    required List<TodoTask> inProgress,
    required List<TodoTask> notCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildStatusColumn(
                    'Not Completed', notCompleted, Colors.redAccent),
                _buildStatusColumn('In Progress', inProgress, Colors.amber),
                _buildStatusColumn('Completed', completed, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusColumn(String title, List<TodoTask> tasks, Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$title (${tasks.length})',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: tasks.isEmpty
                    ? Center(
                        key: ValueKey('empty-$title'),
                        child: const Text('No tasks'),
                      )
                    : ListView.builder(
                        key: ValueKey('list-$title-${tasks.length}'),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return AnimatedSlide(
                            duration:
                                Duration(milliseconds: 220 + (index * 40)),
                            offset: Offset.zero,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFDCD4EF)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('${task.subject} • ${task.type}'),
                                  Text(DateFormat('h:mm a')
                                      .format(task.dateTime)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniSummary(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 4),
            Text('$value',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _monthCalendar(List<TodoTask> allTasks) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final int leadingEmpty = firstDay.weekday - 1;
    final int daysInMonth =
        DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    final int totalCells = leadingEmpty + daysInMonth;
    final int gridCount = ((totalCells / 7).ceil()) * 7;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(_visibleMonth),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            _WeekDayLabel('Mon'),
            _WeekDayLabel('Tue'),
            _WeekDayLabel('Wed'),
            _WeekDayLabel('Thu'),
            _WeekDayLabel('Fri'),
            _WeekDayLabel('Sat'),
            _WeekDayLabel('Sun'),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final int dayNum = index - leadingEmpty + 1;
            if (dayNum <= 0 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }

            final cellDate =
                DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
            final tasksForDay = allTasks
                .where((task) => _sameDay(task.dateTime, cellDate))
                .toList();
            final bool selected = _sameDay(cellDate, _selectedDate);
            final bool today = _sameDay(cellDate, DateTime.now());

            final hasDone =
                tasksForDay.any((task) => task.status == TaskStatus.completed);
            final hasProgress =
                tasksForDay.any((task) => task.status == TaskStatus.inProgress);
            final hasPending = tasksForDay
                .any((task) => task.status == TaskStatus.notCompleted);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = cellDate;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFDCD4FF) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: today
                        ? const Color(0xFF7860F0)
                        : const Color(0xFFE2DDF0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: today
                            ? const Color(0xFF5A44CF)
                            : const Color(0xFF4D4763),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasDone) _dot(Colors.green),
                        if (hasProgress) _dot(Colors.amber),
                        if (hasPending) _dot(Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  const _WeekDayLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
