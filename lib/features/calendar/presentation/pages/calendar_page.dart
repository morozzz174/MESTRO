import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../models/order.dart';
import '../../bloc/calendar_bloc.dart';
import '../../bloc/calendar_event.dart';
import '../../bloc/calendar_state.dart';
import '../widgets/day_events_list.dart';

class CalendarPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const CalendarPage({super.key, this.onNavigate});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        Map<DateTime, List<Order>> events = {};

        if (state is CalendarLoaded) {
          events = state.ordersByDay;
          _selectedDay ??= state.selectedDay;
        }

        return Column(
          children: [
            // Календарь
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TableCalendar<Order>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return events[key] ?? [];
                  },
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Месяц',
                    CalendarFormat.twoWeeks: '2 недели',
                    CalendarFormat.week: 'Неделя',
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    markerSize: 6,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonTextStyle: TextStyle(fontSize: 14),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    context.read<CalendarBloc>().add(CalendarSelectDay(selectedDay));
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();

                      final count = events.length;
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: count > 0
                                ? (events.any((e) => e.isToday)
                                    ? Colors.green
                                    : events.any((e) => e.isPast)
                                        ? Colors.grey
                                        : Colors.orange)
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Фильтр-чипы
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Прошедшие',
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Сегодня',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Будущие',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Список замеров за выбранный день
            if (state is CalendarLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is CalendarLoaded)
              Expanded(
                child: DayEventsList(
                  orders: state.selectedDayOrders,
                  selectedDay: state.selectedDay,
                  onNavigate: widget.onNavigate,
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('Выберите дату для просмотра замеров'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FilterChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
