import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../repositories/impl/user_repository_impl.dart';
import '../../../../utils/app_design.dart';
import '../../../../utils/theme_provider.dart';
import 'dashboard_page.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../calendar/presentation/dialogs/create_appointment_dialog.dart';
import '../../../calendar/bloc/calendar_bloc.dart';
import '../../../calendar/bloc/calendar_event.dart';
import '../../../notifications/services/scheduling_service.dart';
import '../../../../models/order.dart';
import '../../../../screens/checklist_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  static _HomePageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomePageState>();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(onNavigate: switchTab),
      const AppointmentsPage(),
      CalendarPage(onNavigate: switchTab),
      const ProfilePage(),
    ];
    _loadUser();
  }

  Future<void> _loadUser() async {}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MESTRO',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: 'Сменить тему',
            onPressed: () {
              final provider = context.themeProvider;
              if (provider != null) {
                provider.toggleTheme();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () {
              context.read<OrderBloc>().add(LoadOrders());
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: 'Замеры',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Календарь',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesign.radiusLg),
          gradient: AppDesign.secondaryGradient,
          boxShadow: isDark
              ? AppDesign.fabShadowDark
              : AppDesign.fabShadowLight,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _createAppointment,
            borderRadius: BorderRadius.circular(AppDesign.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Замер',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAppointment() async {
    final user = await UserRepositoryImpl().getCurrentUser();
    if (!mounted) return;
    final availableWorkTypes = (user?.selectedWorkTypes ?? [])
        .map((type) => WorkType.values.where((wt) => wt.checklistFile == type))
        .expand((i) => i)
        .toList();

    final order = await CreateAppointmentDialog.show(
      context,
      DateTime.now(),
      availableWorkTypes: availableWorkTypes,
    );
    if (order != null && mounted) {
      context.read<OrderBloc>().add(CreateOrder(order));
      if (order.appointmentDate != null) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            final scheduler = AppointmentNotificationScheduler();
            await scheduler.scheduleForAppointment(order);
          } catch (_) {}
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Замер для "${order.clientName}" создан')),
        );
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChecklistScreen(order: order)),
        );
      }
    }
  }
}
