import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class MedsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const MedsScreen({super.key, required this.onChanged});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final list = await _db.ilaclarListele();
    setState(() => _list = list);
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return 'Devam ediyor';
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _ekle() async {
    final adCtrl = TextEditingController();
    final dozCtrl = TextEditingController();
    final notCtrl = TextEditingController();
    final tarih = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('Yeni İlaç', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: adCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'İlaç adı', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: dozCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Doz', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: notCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Not', labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true || adCtrl.text.trim().isEmpty) return;
    await _db.ilacEkle(ad: adCtrl.text.trim(), tarih: tarih, doz: dozCtrl.text.trim(), not_: notCtrl.text.trim());
    await _yukle();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: const Text('İlaçlar'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _ekle)],
      ),
      body: _list.isEmpty
          ? const Center(child: Text('İlaç kaydı yok', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final m = _list[i];
                final devam = m['bitis'] == null || (m['bitis'] as String).isEmpty;
                return Card(
                  color: const Color(0xFF1E1E22),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(Icons.medication, color: devam ? const Color(0xFF2E9E5B) : Colors.white38),
                    title: Text(m['ad'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${_fmt(m['tarih'])} → ${_fmt(m['bitis'])}${m['doz'] != null && (m['doz'] as String).isNotEmpty ? ' · ${m['doz']}' : ''}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white38),
                      onPressed: () async {
                        await _db.ilacSil(m['id'] as int);
                        await _yukle();
                        widget.onChanged();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
