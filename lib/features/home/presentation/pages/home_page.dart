import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../utils/app_design.dart';
import 'dashboard_page.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../checklists_list/presentation/pages/checklists_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../calendar/presentation/dialogs/create_appointment_dialog.dart';
import '../../../calendar/bloc/calendar_bloc.dart';
import '../../../calendar/bloc/calendar_event.dart';
import '../../../../screens/checklist_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  /// Ключ для доступа к состоянию HomePage из дочерних виджетов
  static _HomePageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomePageState>();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  /// Переключить вкладку (вызывается из дочерних страниц)
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
      const ChecklistsListPage(),
      const ProfilePage(),
    ];
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Резерв для будущей логики (например, обновление BLoC)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppDesign.appBarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppDesign.appBarGradient,
            boxShadow: AppDesign.appBarShadow,
          ),
          child: AppBar(
            title: const Text(
              'MESTRO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Обновить',
                onPressed: () {
                  context.read<OrderBloc>().add(LoadOrders());
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppDesign.primaryDark.withOpacity(0.92),
          boxShadow: AppDesign.bottomBarShadow,
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
              icon: Icon(Icons.assignment_turned_in_outlined),
              selectedIcon: Icon(Icons.assignment_turned_in),
              label: 'Чек-листы',
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
          borderRadius: BorderRadius.circular(AppDesign.radiusButton),
          gradient: AppDesign.accentButtonGradient,
          boxShadow: AppDesign.fabShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _createAppointment,
            borderRadius: BorderRadius.circular(AppDesign.radiusButton),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Замер',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
    final order = await CreateAppointmentDialog.show(context, DateTime.now());
    if (order != null && mounted) {
      context.read<CalendarBloc>().add(CalendarCreateOrder(order));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Замер для "${order.clientName}" создан')),
        );
        // Переход к деталям заявки (чек-листу)
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChecklistScreen(order: order)),
        );
      }
    }
  }
}
