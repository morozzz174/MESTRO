import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../repositories/impl/user_repository_impl.dart';
import '../../../../utils/app_design.dart';
import '../../../../utils/theme_provider.dart';
import 'dashboard_page.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../calendar/presentation/dialogs/create_appointment_dialog.dart';
import '../../../notifications/services/scheduling_service.dart';
import '../../../../models/order.dart';
import '../../../../screens/checklist_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();

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