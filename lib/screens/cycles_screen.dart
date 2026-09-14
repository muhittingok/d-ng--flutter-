import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class CyclesScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const CyclesScreen({super.key, required this.onChanged});

  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final list = await _db.dongulerListele();
    setState(() => _list = list.reversed.toList());
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return 'Devam ediyor';
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _ekleDuzenle([Map<String, dynamic>? kayit]) async {
    final basCtrl = TextEditingController(text: kayit?['baslangic'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final bitCtrl = TextEditingController(text: kayit?['bitis'] ?? '');
    var anov = (kayit?['anovulatuar'] as int? ?? 0) == 1;
    final notCtrl = TextEditingController(text: kayit?['notlar'] ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E22),
          title: Text(kayit == null ? 'Yeni Döngü' : 'Döngüyü Düzenle', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: basCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Başlangıç (YYYY-MM-DD)', labelStyle: TextStyle(color: Colors.white54)),
                ),
                TextField(
                  controller: bitCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Bitiş (boş = devam ediyor)', labelStyle: TextStyle(color: Colors.white54)),
                ),
                SwitchListTile(
                  title: const Text('Anovulatuar', style: TextStyle(color: Colors.white)),
                  value: anov,
                  activeColor: const Color(0xFFFF6F91),
                  onChanged: (v) => setS(() => anov = v),
                ),
                TextField(
                  controller: notCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notlar', labelStyle: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final bas = basCtrl.text.trim();
    final bit = bitCtrl.text.trim().isEmpty ? null : bitCtrl.text.trim();
    if (kayit == null) {
      await _db.donguEkle(baslangic: bas, bitis: bit, anovulatuar: anov, notlar: notCtrl.text.trim());
    } else {
      await _db.donguGuncelle(kayit['id'] as int, baslangic: bas, bitis: bit, anovulatuar: anov, notlar: notCtrl.text.trim());
    }
    await _yukle();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: const Text('Döngü Kayıtları'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _ekleDuzenle()),
        ],
      ),
      body: _list.isEmpty
          ? const Center(child: Text('Henüz döngü yok', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final d = _list[i];
                final devam = d['bitis'] == null || (d['bitis'] as String).isEmpty;
                return Card(
                  color: const Color(0xFF1E1E22),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      '${_fmt(d['baslangic'])} → ${_fmt(d['bitis'])}',
                      style: TextStyle(color: devam ? const Color(0xFFFF6F91) : Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if ((d['anovulatuar'] as int? ?? 0) == 1) 'Anovulatuar',
                        if ((d['notlar'] as String? ?? '').isNotEmpty) d['notlar'],
                      ].join(' · '),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') _ekleDuzenle(d);
                        if (v == 'delete') {
                          await _db.donguSil(d['id'] as int);
                          await _yukle();
                          widget.onChanged();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
