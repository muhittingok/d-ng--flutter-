import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class NotesScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const NotesScreen({super.key, required this.onChanged});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _db = DatabaseHelper.instance;
  final _hizliCtrl = TextEditingController();
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final list = await _db.notlarListele();
    setState(() => _list = list);
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _hizliEkle() async {
    final metin = _hizliCtrl.text.trim();
    if (metin.isEmpty) return;
    final bugun = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _db.notEkle(bugun, metin);
    _hizliCtrl.clear();
    await _yukle();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(title: const Text('Günlük Notlar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hizliCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bugün nasıl hissediyorsun?',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E1E22),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _hizliEkle(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _hizliEkle,
                  icon: const Icon(Icons.send, color: Color(0xFFFF6F91)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _list.isEmpty
                ? const Center(child: Text('Not yok', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final n = _list[i];
                      return Card(
                        color: const Color(0xFF1E1E22),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(n['not_'] ?? '', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(_fmt(n['tarih']), style: const TextStyle(color: Colors.white54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white38),
                            onPressed: () async {
                              await _db.notSil(n['id'] as int);
                              await _yukle();
                              widget.onChanged();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
