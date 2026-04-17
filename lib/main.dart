import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'utils/cost_calculator.dart';
import 'services/price_list_service.dart';
import 'services/app_logger.dart';
import 'utils/theme_provider.dart';
import 'utils/app_theme.dart';
import 'utils/app_design.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ru', null);
  await NotificationService().initialize();

  await _ensureDatabaseTables();
  await _initializePrices();

  runApp(const MestroApp());
}

Future<void> _initializePrices() async {
  try {
    final service = PriceListService();
    final workTypes = [
      'windows',
      'doors',
      'air_conditioners',
      'kitchens',
      'tiles',
      'furniture',
      'engineering',
      'electrical',
      'foundations',
      'walls_box',
      'roofing',
      'facades',
      'metal_structures',
      'external_networks',
      'house_construction',
      'fences',
    ];
    int totalSynced = 0;
    for (final workType in workTypes) {
      final items = await service.getPriceList(workType);
      for (final item in items) {
        CostCalculator.updatePrice(workType, item.id, item.price);
        totalSynced++;
      }
    }
    AppLogger.success(
      'Main',
      'Синхронизировано $totalSynced цен из прайс-листа',
    );
  } catch (e, st) {
    AppLogger.error('Main', 'Ошибка инициализации цен', e, st);
  }
}

Future<void> _ensureDatabaseTables() async {
  try {
    final db = await DatabaseHelper().database;
    final customPricesExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='custom_prices'",
    );
    if (customPricesExists.isEmpty) {
      await db.execute('DROP TABLE IF EXISTS custom_prices');
      await db.execute('''
        CREATE TABLE custom_prices (
          id TEXT PRIMARY KEY, work_type TEXT NOT NULL, item_id TEXT NOT NULL,
          name TEXT NOT NULL, unit TEXT NOT NULL, price REAL NOT NULL,
          formula TEXT, multiply_by_count INTEGER DEFAULT 0, is_custom INTEGER DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_price_work_type ON custom_prices (work_type)',
      );
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_price_unique ON custom_prices (work_type, item_id)',
      );
    }
    final photoExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='photo_annotations'",
    );
    if (photoExists.isEmpty) {
      await db.execute('DROP TABLE IF EXISTS photo_annotations');
      await db.execute('''
        CREATE TABLE photo_annotations (
          id TEXT PRIMARY KEY, order_id TEXT NOT NULL, file_path TEXT NOT NULL,
          annotated_path TEXT, checklist_field_id TEXT, latitude REAL, longitude REAL, timestamp TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_photo_order ON photo_annotations (order_id)',
      );
    }
    final paymentsExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='payments'",
    );
    if (paymentsExists.isEmpty) {
      await db.execute('DROP TABLE IF EXISTS payments');
      await db.execute('''
        CREATE TABLE payments (
          id TEXT PRIMARY KEY, order_id TEXT NOT NULL, amount REAL NOT NULL,
          payment_date TEXT NOT NULL, description TEXT, created_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payment_order ON payments (order_id)',
      );
    }

    final columns = await db.rawQuery('PRAGMA table_info(orders)');
    final columnNames = columns.map((c) => c['name'] as String).toSet();
    final Map<String, String> missingColumns = {};
    if (!columnNames.contains('appointment_date'))
      missingColumns['appointment_date'] = 'TEXT';
    if (!columnNames.contains('appointment_end'))
      missingColumns['appointment_end'] = 'TEXT';
    if (!columnNames.contains('client_phone'))
      missingColumns['client_phone'] = 'TEXT';
    if (!columnNames.contains('notes')) missingColumns['notes'] = 'TEXT';
    if (!columnNames.contains('floor_plan_data'))
      missingColumns['floor_plan_data'] = 'TEXT';
    if (!columnNames.contains('paid_amount'))
      missingColumns['paid_amount'] = 'REAL DEFAULT 0';

    for (final entry in missingColumns.entries) {
      AppLogger.info('Main', 'Добавляем колонку orders.${entry.key}');
      try {
        await db.execute(
          'ALTER TABLE orders ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.success('Main', 'Колонка orders.${entry.key} добавлена');
      } catch (e) {
        AppLogger.error(
          'Main',
          'Ошибка добавления колонки orders.${entry.key}',
          e,
        );
      }
    }
  } catch (e) {
    // Ошибка проверки — не критично
  }
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
      child: ThemeProvider(
        child: MaterialApp(
          title: 'MESTRO',
          debugShowCheckedModeBanner: false,
          theme: AppDesign.lightTheme,
          darkTheme: AppDesign.darkTheme,
          themeMode: ThemeMode.system,
          routes: {
            '/registration': (_) => const RegistrationScreen(),
            '/home': (_) => const HomePage(),
          },
          home: const _AppEntryPoint(),
        ),
      ),
    );
  }
}

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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.architecture_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'MESTRO',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Мастер, Единый Стандарт Точности Расчёта Объекта',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_isRegistered) {
      return const HomePage();
    }

    return const RegistrationScreen();
  }
}
