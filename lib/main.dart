import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'bloc/order_bloc.dart';
import 'bloc/order_event.dart';
import 'bloc/checklist_bloc.dart';
import 'features/calendar/bloc/calendar_bloc.dart';
import 'features/calendar/bloc/calendar_event.dart';
import 'features/notifications/services/notification_service.dart';
import 'database/database_helper.dart';
import 'screens/registration_screen.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  // Инициализация уведомлений
  await NotificationService().initialize();

  runApp(const MestroApp());
}

class MestroApp extends StatelessWidget {
  const MestroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final orderBloc = OrderBloc()..add(LoadOrders());
    final calendarBloc = CalendarBloc()..add(CalendarLoadOrders());
    calendarBloc.syncFromOrderBloc(orderBloc);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: orderBloc),
        BlocProvider(create: (_) => ChecklistBloc()),
        BlocProvider.value(value: calendarBloc),
      ],
      child: MaterialApp(
        title: 'Mestro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
          ),
        ),
        routes: {
          '/registration': (_) => const RegistrationScreen(),
          '/home': (_) => const HomePage(),
        },
        home: const _AppEntryPoint(),
      ),
    );
  }
}

/// Точка входа: проверяет, зарегистрирован ли пользователь
class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  bool _isChecking = true;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final registered = await DatabaseHelper().isUserRegistered();
    if (mounted) {
      setState(() {
        _isRegistered = registered;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isRegistered) {
      return const HomePage();
    }

    return const RegistrationScreen();
  }
}
