import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class LabsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const LabsScreen({super.key, required this.onChanged});

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final list = await _db.tahlillerListele();
    setState(() => _list = list.reversed.toList());
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Color _durumRenk(Map<String, dynamic> t) {
    final deger = t['deger'] as num?;
    final alt = t['ref_alt'] as num?;
    final ust = t['ref_ust'] as num?;
    if (deger == null) return Colors.white38;
    if (alt != null && deger < alt) return const Color(0xFF2F80ED);
    if (ust != null && deger > ust) return const Color(0xFFD64545);
    return const Color(0xFF2E9E5B);
  }

  Future<void> _ekle() async {
    final adCtrl = TextEditingController();
    final degerCtrl = TextEditingController();
    final birimCtrl = TextEditingController();
    final refAltCtrl = TextEditingController();
    final refUstCtrl = TextEditingController();
    final tarih = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('Yeni Tahlil', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: adCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Test adı (LH, FSH...)', labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: degerCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Değer', labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: birimCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Birim', labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: refAltCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Ref. alt', labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: refUstCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Ref. üst', labelStyle: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true || adCtrl.text.trim().isEmpty) return;

    await _db.tahlilEkle({
      'test_adi': adCtrl.text.trim(),
      'tarih': tarih,
      'deger': double.tryParse(degerCtrl.text.replaceAll(',', '.')),
      'birim': birimCtrl.text.trim(),
      'ref_alt': double.tryParse(refAltCtrl.text.replaceAll(',', '.')),
      'ref_ust': double.tryParse(refUstCtrl.text.replaceAll(',', '.')),
      'laboratuvar': '',
      'gorsel_yolu': '',
      'adet_durumu': 'bilinmiyor',
    });
    await _yukle();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: const Text('Tahliller'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _ekle)],
      ),
      body: _list.isEmpty
          ? const Center(child: Text('Tahlil kaydı yok', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final t = _list[i];
                final renk = _durumRenk(t);
                return Card(
                  color: const Color(0xFF1E1E22),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(t['test_adi'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${_fmt(t['tarih'])}  ·  ${t['deger'] ?? t['deger_metin'] ?? '-'} ${t['birim'] ?? ''}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: renk, shape: BoxShape.circle)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white38),
                          onPressed: () async {
                            await _db.tahlilSil(t['id'] as int);
                            await _yukle();
                            widget.onChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
