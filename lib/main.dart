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
import 'utils/app_design.dart';

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
          scaffoldBackgroundColor: AppDesign.pageBackground,
          primaryColor: AppDesign.deepSteelBlue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppDesign.deepSteelBlue,
            primary: AppDesign.deepSteelBlue,
            secondary: AppDesign.accentTeal,
            surface: AppDesign.cardBackground,
            brightness: Brightness.light,
          ),
          useMaterial3: false, // Using custom design system
          fontFamily: AppDesign.fontFamily,
          textTheme: const TextTheme(
            displayLarge: AppDesign.displayStyle,
            titleLarge: AppDesign.titleStyle,
            titleMedium: AppDesign.subtitleStyle,
            bodyLarge: AppDesign.bodyStyle,
            bodyMedium: AppDesign.bodyStyle,
            labelSmall: AppDesign.captionStyle,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppDesign.primaryDark,
            foregroundColor: Colors.white,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontFamily: AppDesign.fontFamily,
            ),
            iconTheme: const IconThemeData(color: AppDesign.warmTaupe),
            shadow: AppDesign.appBarShadow,
            toolbarHeight: AppDesign.appBarHeight,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: AppDesign.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusCard),
              side: BorderSide(color: AppDesign.midBlueGrayBorder),
            ),
            shadowColor: AppDesign.deepSteelBlueCardShadow,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 0,
            backgroundColor: AppDesign.accentTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusButton),
            ),
            splashColor: AppDesign.accentTeal.withOpacity(0.2),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppDesign.warmTaupe.withOpacity(0.12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDesign.spacing16,
              vertical: AppDesign.spacing12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusInput),
              borderSide: BorderSide(
                color: AppDesign.midBlueGray.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusInput),
              borderSide: BorderSide(
                color: AppDesign.midBlueGray.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusInput),
              borderSide: const BorderSide(
                color: AppDesign.deepSteelBlue,
                width: 1.5,
              ),
            ),
            labelStyle: const TextStyle(
              color: AppDesign.midBlueGray,
              fontSize: 15,
            ),
            hintStyle: const TextStyle(
              color: AppDesign.warmTaupe,
              fontSize: 15,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: AppDesign.primaryButtonStyle,
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: AppDesign.outlinedButtonStyle,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppDesign.deepSteelBlue.withOpacity(0.12),
            selectedColor: AppDesign.deepSteelBlue,
            labelStyle: const TextStyle(
              color: AppDesign.deepSteelBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusChip),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
          dividerTheme: DividerThemeData(
            color: AppDesign.midBlueGraySeparator,
            thickness: 1,
            space: 0,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppDesign.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusCard),
            ),
            elevation: 8,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusListItem),
            ),
            backgroundColor: AppDesign.primaryDark,
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: AppDesign.fontFamily,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppDesign.primaryDark,
            selectedItemColor: AppDesign.accentTeal,
            unselectedItemColor: AppDesign.warmTaupe,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(
              color: AppDesign.accentTeal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              color: AppDesign.warmTaupe,
              fontSize: 12,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppDesign.primaryDark,
            indicatorColor: AppDesign.accentTeal.withOpacity(0.18),
            elevation: 0,
            height: AppDesign.bottomBarHeight,
            surfaceTintColor: Colors.transparent,
            shadowColor: AppDesign.primaryDark,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: AppDesign.accentTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                );
              }
              return const TextStyle(color: AppDesign.warmTaupe, fontSize: 12);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: AppDesign.accentTeal,
                  size: 24,
                );
              }
              return const IconThemeData(color: AppDesign.warmTaupe, size: 24);
            }),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isRegistered) {
      return const HomePage();
    }

    return const RegistrationScreen();
  }
}
