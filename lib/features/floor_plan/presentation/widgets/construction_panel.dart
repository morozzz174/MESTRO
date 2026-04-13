import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../utils/app_design.dart';
import '../../models/editor_state.dart';

/// Панель конструктивных элементов (стены, фундамент, кровля, перекрытия, инженерия)
class ConstructionPanel extends StatefulWidget {
  final EditorState state;
  final ValueChanged<EditorState> onChanged;

  const ConstructionPanel({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  State<ConstructionPanel> createState() => _ConstructionPanelState();
}

class _ConstructionPanelState extends State<ConstructionPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppDesign.deepSteelBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppDesign.deepSteelBlue, AppDesign.accentTeal],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.construction, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Конструктив',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Стены', icon: Icon(Icons.wallpaper, size: 16)),
                    Tab(
                      text: 'Фундамент',
                      icon: Icon(Icons.foundation, size: 16),
                    ),
                    Tab(text: 'Кровля', icon: Icon(Icons.roofing, size: 16)),
                    Tab(text: 'Перекрытия', icon: Icon(Icons.layers, size: 16)),
                    Tab(
                      text: 'Инженерия',
                      icon: Icon(Icons.plumbing, size: 16),
                    ),
                    Tab(text: 'Оси', icon: Icon(Icons.grid_on, size: 16)),
                  ],
                ),
              ],
            ),
          ),
          // Контент
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWallsTab(),
                _buildFoundationTab(),
                _buildRoofTab(),
                _buildCeilingsTab(),
                _buildEngineeringTab(),
                _buildAxisLinesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== СТЕНЫ ====================
  Widget _buildWallsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text(
              'Стены',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addWall,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.accentTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.state.walls.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Нет стен. Нажмите "Добавить"',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ...widget.state.walls.map((w) => _buildWallCard(w)),
      ],
    );
  }

  Widget _buildWallCard(WallState wall) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          wall.isLoadBearing ? Icons.shield : Icons.wallpaper,
          color: wall.type == 'exterior' ? Colors.red : Colors.blue,
        ),
        title: Text(
          '${_wallTypeLabel(wall.type)} — ${_materialLabel(wall.material)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Толщ: ${wall.thickness}м | Выс: ${wall.height}м | L: ${wall.length.toStringAsFixed(2)}м',
          style: const TextStyle(fontSize: 11),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSliderRow(
                  'Толщина (м)',
                  wall.thickness,
                  0.1,
                  0.6,
                  (v) => _updateWall(wall.copyWith(thickness: v)),
                ),
                _buildSliderRow(
                  'Высота (м)',
                  wall.height,
                  2.0,
                  4.0,
                  (v) => _updateWall(wall.copyWith(height: v)),
                ),
                _buildSliderRow(
                  'Утепление (м)',
                  wall.insulationThickness,
                  0.0,
                  0.3,
                  (v) => _updateWall(wall.copyWith(insulationThickness: v)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Несущая:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Switch(
                      value: wall.isLoadBearing,
                      onChanged: (v) =>
                          _updateWall(wall.copyWith(isLoadBearing: v)),
                      activeColor: AppDesign.accentTeal,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteWall(wall),
                    ),
                  ],
                ),
                // Тип стены
                DropdownButton<String>(
                  value: wall.type,
                  items: _wallTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_wallTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _updateWall(wall.copyWith(type: v));
                  },
                ),
                const SizedBox(width: 8),
                // Материал
                DropdownButton<String>(
                  value: wall.material,
                  items: _materials
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_materialLabel(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _updateWall(wall.copyWith(material: v));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addWall() {
    final id = const Uuid().v4();
    final newWall = WallState(
      id: id,
      x1: 0,
      y1: 0,
      x2: widget.state.totalWidth,
      y2: 0,
      type: 'exterior',
    );
    widget.onChanged(
      widget.state.copyWith(walls: [...widget.state.walls, newWall]),
    );
  }

  void _updateWall(WallState wall) {
    widget.onChanged(
      widget.state.copyWith(
        walls: widget.state.walls
            .map((w) => w.id == wall.id ? wall : w)
            .toList(),
      ),
    );
  }

  void _deleteWall(WallState wall) {
    widget.onChanged(
      widget.state.copyWith(
        walls: widget.state.walls.where((w) => w.id != wall.id).toList(),
      ),
    );
  }

  static const _wallTypes = [
    'exterior',
    'interior',
    'partition',
    'foundation',
    'retaining',
  ];
  static const _materials = [
    'brick',
    'gasBlockD400',
    'gasBlockD500',
    'gasBlockD600',
    'concrete',
    'timber',
    'keramoblock',
    'foamBlock',
    'sipPanel',
  ];

  String _wallTypeLabel(String t) {
    switch (t) {
      case 'exterior':
        return 'Наружная';
      case 'interior':
        return 'Внутренняя';
      case 'partition':
        return 'Перегородка';
      case 'foundation':
        return 'Фундаментная';
      case 'retaining':
        return 'Подпорная';
      default:
        return t;
    }
  }

  String _materialLabel(String m) {
    switch (m) {
      case 'brick':
        return 'Кирпич';
      case 'gasBlockD400':
        return 'Газобетон D400';
      case 'gasBlockD500':
        return 'Газобетон D500';
      case 'gasBlockD600':
        return 'Газобетон D600';
      case 'concrete':
        return 'Ж/Б';
      case 'timber':
        return 'Брус';
      case 'keramoblock':
        return 'Керамоблок';
      case 'foamBlock':
        return 'Пеноблок';
      case 'sipPanel':
        return 'СИП';
      default:
        return m;
    }
  }

  // ==================== ФУНДАМЕНТ ====================
  Widget _buildFoundationTab() {
    final f = widget.state.foundation;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text(
              'Фундамент',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (f == null)
              ElevatedButton.icon(
                onPressed: _addFoundation,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Добавить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.accentTeal,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        if (f != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: f.type,
                    items: _foundationTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_foundationTypeLabel(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _updateFoundation(f.copyWith(type: v));
                    },
                  ),
                  _buildSliderRow(
                    'Ширина (м)',
                    f.width,
                    0.2,
                    1.0,
                    (v) => _updateFoundation(f.copyWith(width: v)),
                  ),
                  _buildSliderRow(
                    'Глубина (м)',
                    f.depth,
                    0.5,
                    2.5,
                    (v) => _updateFoundation(f.copyWith(depth: v)),
                  ),
                  _buildSliderRow(
                    'Высота (м)',
                    f.height,
                    0.3,
                    1.0,
                    (v) => _updateFoundation(f.copyWith(height: v)),
                  ),
                  _buildSliderRow(
                    'Песчаная подушка (м)',
                    f.sandCushionThickness,
                    0.0,
                    0.5,
                    (v) =>
                        _updateFoundation(f.copyWith(sandCushionThickness: v)),
                  ),
                  const SizedBox(height: 8),
                  _switchRow(
                    'Гидроизоляция',
                    f.hasWaterproofing,
                    (v) => _updateFoundation(f.copyWith(hasWaterproofing: v)),
                  ),
                  _switchRow(
                    'Утепление',
                    f.hasInsulation,
                    (v) => _updateFoundation(f.copyWith(hasInsulation: v)),
                  ),
                  _switchRow(
                    'Дренаж',
                    f.hasDrainage,
                    (v) => _updateFoundation(f.copyWith(hasDrainage: v)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Бетон:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: f.concreteGrade,
                        items: _concreteGrades
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final classMap = {
                              'М200': 'B15',
                              'М250': 'B20',
                              'М300': 'B22_5',
                              'М350': 'B25',
                              'М400': 'B30',
                            };
                            _updateFoundation(
                              f.copyWith(
                                concreteGrade: v,
                                concreteClass: classMap[v] ?? 'B22_5',
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Арматура ⌀', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      DropdownButton<int>(
                        value: f.mainBarDiameter,
                        items: [8, 10, 12, 14, 16, 18, 20, 25]
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text('${d}мм'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null)
                            _updateFoundation(f.copyWith(mainBarDiameter: v));
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('×'),
                      const SizedBox(width: 4),
                      DropdownButton<int>(
                        value: f.mainBarsCount,
                        items: [4, 6, 8, 10, 12]
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c}шт'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null)
                            _updateFoundation(f.copyWith(mainBarsCount: v));
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: _deleteFoundation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _addFoundation() {
    widget.onChanged(
      widget.state.copyWith(foundation: FoundationState(id: const Uuid().v4())),
    );
  }

  void _updateFoundation(FoundationState f) {
    widget.onChanged(widget.state.copyWith(foundation: f));
  }

  void _deleteFoundation() {
    widget.onChanged(widget.state.copyWith(foundation: null));
  }

  static const _foundationTypes = ['strip', 'slab', 'pile', 'column', 'screw'];
  static const _concreteGrades = ['М200', 'М250', 'М300', 'М350', 'М400'];

  String _foundationTypeLabel(String t) {
    switch (t) {
      case 'strip':
        return 'Ленточный';
      case 'slab':
        return 'Плитный';
      case 'pile':
        return 'Свайный';
      case 'column':
        return 'Столбчатый';
      case 'screw':
        return 'Винтовые сваи';
      default:
        return t;
    }
  }

  // ==================== КРОВЛЯ ====================
  Widget _buildRoofTab() {
    final r = widget.state.roof;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text(
              'Кровля',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (r == null)
              ElevatedButton.icon(
                onPressed: _addRoof,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Добавить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.accentTeal,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        if (r != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: r.type,
                    items: _roofTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_roofTypeLabel(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _updateRoof(r.copyWith(type: v));
                    },
                  ),
                  _buildSliderRow(
                    'Площадь (м²)',
                    r.area,
                    20,
                    500,
                    (v) => _updateRoof(r.copyWith(area: v)),
                  ),
                  _buildSliderRow(
                    'Угол наклона (°)',
                    r.slopeAngle,
                    5,
                    60,
                    (v) => _updateRoof(r.copyWith(slopeAngle: v)),
                  ),
                  _buildSliderRow(
                    'Утепление (м)',
                    r.insulationThickness,
                    0.0,
                    0.4,
                    (v) => _updateRoof(r.copyWith(insulationThickness: v)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Материал:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: r.roofingMaterial,
                        items: _roofMaterials
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(_roofMaterialLabel(m)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null)
                            _updateRoof(r.copyWith(roofingMaterial: v));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _switchRow(
                    'Гидро-мембрана',
                    r.hasWaterproofingMembrane,
                    (v) => _updateRoof(r.copyWith(hasWaterproofingMembrane: v)),
                  ),
                  _switchRow(
                    'Пароизоляция',
                    r.hasVaporBarrier,
                    (v) => _updateRoof(r.copyWith(hasVaporBarrier: v)),
                  ),
                  _switchRow(
                    'Снегозадержатели',
                    r.hasSnowRetention,
                    (v) => _updateRoof(r.copyWith(hasSnowRetention: v)),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteRoof,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _addRoof() {
    widget.onChanged(
      widget.state.copyWith(roof: RoofState(id: const Uuid().v4())),
    );
  }

  void _updateRoof(RoofState r) {
    widget.onChanged(widget.state.copyWith(roof: r));
  }

  void _deleteRoof() {
    widget.onChanged(widget.state.copyWith(roof: null));
  }

  static const _roofTypes = ['gable', 'hip', 'shed', 'flat', 'mansard', 'tent'];
  static const _roofMaterials = [
    'metalTile',
    'softRoof',
    'profNail',
    'seam',
    'ceramicTile',
    'ondulin',
  ];

  String _roofTypeLabel(String t) {
    switch (t) {
      case 'gable':
        return 'Двускатная';
      case 'hip':
        return 'Вальмовая';
      case 'shed':
        return 'Односкатная';
      case 'flat':
        return 'Плоская';
      case 'mansard':
        return 'Мансардная';
      case 'tent':
        return 'Шатровая';
      default:
        return t;
    }
  }

  String _roofMaterialLabel(String m) {
    switch (m) {
      case 'metalTile':
        return 'Металлочерепица';
      case 'softRoof':
        return 'Мягкая кровля';
      case 'profNail':
        return 'Профнастил';
      case 'seam':
        return 'Фальцевая';
      case 'ceramicTile':
        return 'Керамическая';
      case 'ondulin':
        return 'Ондулин';
      default:
        return m;
    }
  }

  // ==================== ПЕРЕКРЫТИЯ ====================
  Widget _buildCeilingsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text(
              'Перекрытия',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addCeiling,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.accentTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.state.ceilings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Нет перекрытий',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ...widget.state.ceilings.map((c) => _buildCeilingCard(c)),
      ],
    );
  }

  Widget _buildCeilingCard(CeilingState ceiling) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.layers, color: Colors.blue),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: ceiling.type,
                  items: _ceilingTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_ceilingTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null)
                      _updateCeiling(ceiling, ceiling.copyWith(type: v));
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => _deleteCeiling(ceiling),
                ),
              ],
            ),
            _buildSliderRow(
              'Толщина (м)',
              ceiling.thickness,
              0.1,
              0.4,
              (v) => _updateCeiling(ceiling, ceiling.copyWith(thickness: v)),
            ),
            _switchRow(
              'Звукоизоляция',
              ceiling.hasSoundproofing,
              (v) => _updateCeiling(
                ceiling,
                ceiling.copyWith(hasSoundproofing: v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCeiling() {
    final id = const Uuid().v4();
    widget.onChanged(
      widget.state.copyWith(
        ceilings: [
          ...widget.state.ceilings,
          CeilingState(id: id),
        ],
      ),
    );
  }

  void _updateCeiling(CeilingState old, CeilingState updated) {
    widget.onChanged(
      widget.state.copyWith(
        ceilings: widget.state.ceilings
            .map((c) => c.id == old.id ? updated : c)
            .toList(),
      ),
    );
  }

  void _deleteCeiling(CeilingState c) {
    widget.onChanged(
      widget.state.copyWith(
        ceilings: widget.state.ceilings.where((x) => x.id != c.id).toList(),
      ),
    );
  }

  static const _ceilingTypes = [
    'monolithic',
    'precast',
    'wooden',
    'metal',
    'composite',
  ];

  String _ceilingTypeLabel(String t) {
    switch (t) {
      case 'monolithic':
        return 'Монолитное';
      case 'precast':
        return 'Сборное (плиты)';
      case 'wooden':
        return 'Деревянное';
      case 'metal':
        return 'Металлическое';
      case 'composite':
        return 'Композитное';
      default:
        return t;
    }
  }

  // ==================== ИНЖЕНЕРИЯ ====================
  Widget _buildEngineeringTab() {
    final es = widget.state.engineeringSystems;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Инженерные системы',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildEngineeringSection(
          '🔥 Отопление',
          es?.heating,
          () => _initHeating(),
          (v) => _updateHeating(v),
          _buildHeatingForm,
        ),
        _buildEngineeringSection(
          '💧 Водоснабжение',
          es?.waterSupply,
          () => _initWaterSupply(),
          (v) => _updateWaterSupply(v),
          _buildWaterSupplyForm,
        ),
        _buildEngineeringSection(
          '🔌 Электрика',
          es?.electrical,
          () => _initElectrical(),
          (v) => _updateElectrical(v),
          _buildElectricalForm,
        ),
        _buildEngineeringSection(
          '💨 Вентиляция',
          es?.ventilation,
          () => _initVentilation(),
          (v) => _updateVentilation(v),
          _buildVentilationForm,
        ),
        _buildEngineeringSection(
          '🚿 Канализация',
          es?.sewage,
          () => _initSewage(),
          (v) => _updateSewage(v),
          _buildSewageForm,
        ),
      ],
    );
  }

  Widget _buildEngineeringSection<T>(
    String title,
    T? data,
    VoidCallback onInit,
    void Function(T) onUpdate,
    Widget Function(T) buildForm,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: data == null
          ? ListTile(
              title: Text(title),
              trailing: ElevatedButton(
                onPressed: onInit,
                child: const Text('Включить'),
              ),
            )
          : ExpansionTile(
              title: Text(title),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      buildForm(data),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => onUpdate(data as dynamic),
                          child: const Text(
                            'Отключить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _initHeating() {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: HeatingSystemState(),
          waterSupply: es?.waterSupply,
          sewage: es?.sewage,
          ventilation: es?.ventilation,
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  void _updateHeating(HeatingSystemState h) {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: null,
          waterSupply: es?.waterSupply,
          sewage: es?.sewage,
          ventilation: es?.ventilation,
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  Widget _buildHeatingForm(HeatingSystemState h) {
    return Column(
      children: [
        DropdownButton<String>(
          value: h.type,
          items:
              [
                    ('radiators', 'Радиаторы'),
                    ('warmFloor', 'Тёплый пол'),
                    ('convectors', 'Конвекторы'),
                    ('infrared', 'Инфракрасное'),
                    ('combined', 'Комбинированное'),
                  ]
                  .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
          onChanged: (v) {
            if (v != null) {
              final es = widget.state.engineeringSystems!;
              widget.onChanged(
                widget.state.copyWith(
                  engineeringSystems: EngineeringSystemsState(
                    heating: HeatingSystemState(
                      type: v,
                      radiatorCount: h.radiatorCount,
                      pipeLength: h.pipeLength,
                      boilerPower: h.boilerPower,
                      hasWarmFloor: h.hasWarmFloor,
                      warmFloorArea: h.warmFloorArea,
                    ),
                    waterSupply: es.waterSupply,
                    sewage: es.sewage,
                    ventilation: es.ventilation,
                    electrical: es.electrical,
                    gas: es.gas,
                  ),
                ),
              );
            }
          },
        ),
        _buildIntRow('Радиаторы', h.radiatorCount, 0, 50, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: HeatingSystemState(
                  type: h.type,
                  radiatorCount: v,
                  pipeLength: h.pipeLength,
                  boilerPower: h.boilerPower,
                  hasWarmFloor: h.hasWarmFloor,
                  warmFloorArea: h.warmFloorArea,
                ),
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: es.electrical,
                gas: es.gas,
              ),
            ),
          );
        }),
        _buildSliderRow('Мощность котла (кВт)', h.boilerPower, 0, 100, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: HeatingSystemState(
                  type: h.type,
                  radiatorCount: h.radiatorCount,
                  pipeLength: h.pipeLength,
                  boilerPower: v,
                  hasWarmFloor: h.hasWarmFloor,
                  warmFloorArea: h.warmFloorArea,
                ),
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: es.electrical,
                gas: es.gas,
              ),
            ),
          );
        }),
        _switchRow('Тёплый пол', h.hasWarmFloor, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: HeatingSystemState(
                  type: h.type,
                  radiatorCount: h.radiatorCount,
                  pipeLength: h.pipeLength,
                  boilerPower: h.boilerPower,
                  hasWarmFloor: v,
                  warmFloorArea: h.warmFloorArea,
                ),
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: es.electrical,
                gas: es.gas,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _initWaterSupply() {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: WaterSupplyState(),
          sewage: es?.sewage,
          ventilation: es?.ventilation,
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  void _updateWaterSupply(WaterSupplyState w) {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: null,
          sewage: es?.sewage,
          ventilation: es?.ventilation,
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  Widget _buildWaterSupplyForm(WaterSupplyState w) {
    return Column(
      children: [
        _buildIntRow('Точки водоразбора', w.fixtureCount, 0, 20, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: WaterSupplyState(
                  coldPipeLength: w.coldPipeLength,
                  hotPipeLength: w.hotPipeLength,
                  fixtureCount: v,
                  hasWaterHeater: w.hasWaterHeater,
                  waterHeaterVolume: w.waterHeaterVolume,
                ),
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: es.electrical,
                gas: es.gas,
              ),
            ),
          );
        }),
        _switchRow('Водонагреватель', w.hasWaterHeater, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: WaterSupplyState(
                  coldPipeLength: w.coldPipeLength,
                  hotPipeLength: w.hotPipeLength,
                  fixtureCount: w.fixtureCount,
                  hasWaterHeater: v,
                  waterHeaterVolume: w.waterHeaterVolume,
                ),
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: es.electrical,
                gas: es.gas,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _initElectrical() {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: es?.waterSupply,
          sewage: es?.sewage,
          ventilation: es?.ventilation,
          electrical: ElectricalState(),
          gas: es?.gas,
        ),
      ),
    );
  }

  void _updateElectrical(ElectricalState e) {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: es?.waterSupply,
          sewage: es?.sewage,
          ventilation: es?.ventilation,
          electrical: null,
          gas: es?.gas,
        ),
      ),
    );
  }

  Widget _buildElectricalForm(ElectricalState e) {
    return Column(
      children: [
        _buildIntRow('Розетки', e.socketCount, 0, 100, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: ElectricalState(
                  cableLength: e.cableLength,
                  socketCount: v,
                  switchCount: e.switchCount,
                  lightPointCount: e.lightPointCount,
                  breakerCount: e.breakerCount,
                  hasRCD: e.hasRCD,
                  hasGrounding: e.hasGrounding,
                  hasLightningProtection: e.hasLightningProtection,
                  hasSmartHome: e.hasSmartHome,
                ),
                gas: es.gas,
              ),
            ),
          );
        }),
        _buildIntRow('Выключатели', e.switchCount, 0, 50, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: ElectricalState(
                  cableLength: e.cableLength,
                  socketCount: e.socketCount,
                  switchCount: v,
                  lightPointCount: e.lightPointCount,
                  breakerCount: e.breakerCount,
                  hasRCD: e.hasRCD,
                  hasGrounding: e.hasGrounding,
                  hasLightningProtection: e.hasLightningProtection,
                  hasSmartHome: e.hasSmartHome,
                ),
                gas: es.gas,
              ),
            ),
          );
        }),
        _switchRow('УЗО', e.hasRCD, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: ElectricalState(
                  cableLength: e.cableLength,
                  socketCount: e.socketCount,
                  switchCount: e.switchCount,
                  lightPointCount: e.lightPointCount,
                  breakerCount: e.breakerCount,
                  hasRCD: v,
                  hasGrounding: e.hasGrounding,
                  hasLightningProtection: e.hasLightningProtection,
                  hasSmartHome: e.hasSmartHome,
                ),
                gas: es.gas,
              ),
            ),
          );
        }),
        _switchRow('Заземление', e.hasGrounding, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: es.ventilation,
                electrical: ElectricalState(
                  cableLength: e.cableLength,
                  socketCount: e.socketCount,
                  switchCount: e.switchCount,
                  lightPointCount: e.lightPointCount,
                  breakerCount: e.breakerCount,
                  hasRCD: e.hasRCD,
                  hasGrounding: v,
                  hasLightningProtection: e.hasLightningProtection,
                  hasSmartHome: e.hasSmartHome,
                ),
                gas: es.gas,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _initVentilation() {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: es?.waterSupply,
          sewage: es?.sewage,
          ventilation: VentilationState(),
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  void _updateVentilation(VentilationState v) {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: es?.waterSupply,
          sewage: es?.sewage,
          ventilation: null,
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  Widget _buildVentilationForm(VentilationState v) {
    return Column(
      children: [
        _buildIntRow('Вытяжные точки', v.exhaustPoints, 0, 20, (val) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: es.waterSupply,
                sewage: es.sewage,
                ventilation: VentilationState(
                  type: v.type,
                  exhaustPoints: val,
                  supplyPoints: v.supplyPoints,
                  ductLength: v.ductLength,
                  hasRecuperator: v.hasRecuperator,
                ),
                electrical: es.electrical,
                gas: es.gas,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _initSewage() {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: es?.waterSupply,
          sewage: SewageState(),
          ventilation: es?.ventilation,
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  void _updateSewage(SewageState s) {
    final es = widget.state.engineeringSystems;
    widget.onChanged(
      widget.state.copyWith(
        engineeringSystems: EngineeringSystemsState(
          heating: es?.heating,
          waterSupply: es?.waterSupply,
          sewage: null,
          ventilation: es?.ventilation,
          electrical: es?.electrical,
          gas: es?.gas,
        ),
      ),
    );
  }

  Widget _buildSewageForm(SewageState s) {
    return Column(
      children: [
        _switchRow('Септик', s.hasSeptic, (v) {
          final es = widget.state.engineeringSystems!;
          widget.onChanged(
            widget.state.copyWith(
              engineeringSystems: EngineeringSystemsState(
                heating: es.heating,
                waterSupply: es.waterSupply,
                sewage: SewageState(
                  pipeLength: s.pipeLength,
                  fixtureCount: s.fixtureCount,
                  hasSeptic: v,
                  septicType: s.septicType,
                ),
                ventilation: es.ventilation,
                electrical: es.electrical,
                gas: es.gas,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==================== ОСЕВЫЕ ЛИНИИ ====================
  Widget _buildAxisLinesTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text(
              'Осевые линии',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addAxisLine,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.accentTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.state.axisLines.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Нет осевых линий',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ...widget.state.axisLines.map((a) => _buildAxisCard(a)),
      ],
    );
  }

  Widget _buildAxisCard(AxisLineState axis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: const Icon(Icons.grid_on, color: Colors.red),
        title: Text('Ось ${axis.label}'),
        subtitle: Text('(${axis.x1}, ${axis.y1}) → (${axis.x2}, ${axis.y2})'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _editAxis(axis),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: () => _deleteAxis(axis),
            ),
          ],
        ),
      ),
    );
  }

  void _addAxisLine() {
    final n = widget.state.axisLines.length + 1;
    final label = n <= 26 ? String.fromCharCode(64 + n) : '$n';
    widget.onChanged(
      widget.state.copyWith(
        axisLines: [
          ...widget.state.axisLines,
          AxisLineState(
            id: const Uuid().v4(),
            label: label,
            x1: 0,
            y1: 0,
            x2: widget.state.totalWidth,
            y2: 0,
          ),
        ],
      ),
    );
  }

  void _editAxis(AxisLineState axis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Редактировать ось ${axis.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSliderRow(
              'X1',
              axis.x1,
              0,
              widget.state.totalWidth,
              (v) => _updateAxis(axis.copyWith(x1: v)),
            ),
            _buildSliderRow(
              'Y1',
              axis.y1,
              0,
              widget.state.totalHeight,
              (v) => _updateAxis(axis.copyWith(y1: v)),
            ),
            _buildSliderRow(
              'X2',
              axis.x2,
              0,
              widget.state.totalWidth,
              (v) => _updateAxis(axis.copyWith(x2: v)),
            ),
            _buildSliderRow(
              'Y2',
              axis.y2,
              0,
              widget.state.totalHeight,
              (v) => _updateAxis(axis.copyWith(y2: v)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _updateAxis(AxisLineState axis) {
    widget.onChanged(
      widget.state.copyWith(
        axisLines: widget.state.axisLines
            .map((a) => a.id == axis.id ? axis : a)
            .toList(),
      ),
    );
  }

  void _deleteAxis(AxisLineState axis) {
    widget.onChanged(
      widget.state.copyWith(
        axisLines: widget.state.axisLines
            .where((a) => a.id != axis.id)
            .toList(),
      ),
    );
  }

  // ==================== УТИЛИТЫ ====================
  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 100,
            onChanged: onChanged,
            activeColor: AppDesign.accentTeal,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildIntRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
            activeColor: AppDesign.accentTeal,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppDesign.accentTeal,
        ),
      ],
    );
  }
}
