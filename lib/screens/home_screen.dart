import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../services/prediction.dart';
import '../widgets/cycle_ring.dart';
import 'cycles_screen.dart';
import 'meds_screen.dart';
import 'labs_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _donguler = [];
  String _profil = 'normal';
  PredictionResult? _prediction;
  int? _gun;
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _loading = true);
    final donguler = await _db.dongulerListele();
    final profil = await _db.getProfil();
    final pred = predict(donguler, profil);
    final gun = cycleDay(donguler);
    setState(() {
      _donguler = donguler;
      _profil = profil;
      _prediction = pred;
      _gun = gun;
      _loading = false;
    });
  }

  Future<void> _adetBugunBasladi() async {
    final acik = _donguler.where((d) => d['bitis'] == null || (d['bitis'] as String).isEmpty);
    if (acik.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zaten devam eden bir döngü kaydı var. Önce onu bitirin.')),
      );
      return;
    }
    final bugun = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _db.donguEkle(baslangic: bugun);
    await _yukle();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adet başlangıcı kaydedildi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6F91)))
            : IndexedStack(
                index: _tabIndex,
                children: [
                  _buildHomeTab(),
                  CyclesScreen(onChanged: _yukle),
                  MedsScreen(onChanged: _yukle),
                  LabsScreen(onChanged: _yukle),
                  NotesScreen(onChanged: _yukle),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF1A1A1E),
        indicatorColor: const Color(0xFFFF6F91).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Özet'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Döngü'),
          NavigationDestination(icon: Icon(Icons.medication_outlined), selectedIcon: Icon(Icons.medication), label: 'İlaç'),
          NavigationDestination(icon: Icon(Icons.science_outlined), selectedIcon: Icon(Icons.science), label: 'Tahlil'),
          NavigationDestination(icon: Icon(Icons.notes_outlined), selectedIcon: Icon(Icons.notes), label: 'Notlar'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final pred = _prediction ?? PredictionResult(varMi: false);
    return RefreshIndicator(
      onRefresh: _yukle,
      color: const Color(0xFFFF6F91),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          children: [
            // Üst bar
            Row(
              children: [
                const Text(
                  '🌸 Takip',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                // Profil chip
                GestureDetector(
                  onTap: _profilDegistir,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _profil == 'pcos' ? const Color(0xFF9C6ADE).withOpacity(0.25) : const Color(0xFFFF6F91).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _profil == 'pcos' ? const Color(0xFF9C6ADE) : const Color(0xFFFF6F91),
                      ),
                    ),
                    child: Text(
                      _profil == 'pcos' ? 'PCOS / PMOS' : 'Normal',
                      style: TextStyle(
                        color: _profil == 'pcos' ? const Color(0xFF9C6ADE) : const Color(0xFFFF6F91),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    _yukle();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Dairesel halka
            CycleRing(
              prediction: pred,
              gun: _gun,
              profil: _profil,
              onTapPhaseInfo: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evre bilgisi yakında eklenecek')),
                );
              },
            ),
            const SizedBox(height: 28),

            // Hızlı aksiyonlar
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.water_drop,
                    label: 'Adetim Bugün\nBaşladı',
                    color: const Color(0xFFFF6F91),
                    onTap: _adetBugunBasladi,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_calendar,
                    label: 'Döngü\nEkle / Düzenle',
                    color: const Color(0xFF9C6ADE),
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.medication,
                    label: 'İlaç\nKaydet',
                    color: const Color(0xFF2E9E5B),
                    onTap: () => setState(() => _tabIndex = 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.science,
                    label: 'Tahlil\nEkle',
                    color: const Color(0xFF2F80ED),
                    onTap: () => setState(() => _tabIndex = 3),
                  ),
                ),
              ],
            ),

            if (pred.ortDongu != null) ...[
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Özet', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      'Ortalama döngü: ${pred.ortDongu!.toStringAsFixed(1)} gün'
                      '${pred.ortKanama != null ? '  ·  Kanama: ${pred.ortKanama!.toStringAsFixed(1)} gün' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    if (pred.uyari != null) ...[
                      const SizedBox(height: 8),
                      Text(pred.uyari!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _profilDegistir() async {
    final yeni = _profil == 'pcos' ? 'normal' : 'pcos';
    await _db.setProfil(yeni);
    await _yukle();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
