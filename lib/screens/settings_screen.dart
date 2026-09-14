import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper.instance;
  String _profil = 'normal';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final p = await _db.getProfil();
    setState(() => _profil = p);
  }

  Future<void> _iceAktar() async {
    setState(() => _busy = true);
    try {
      final msg = await _db.iceAktarDb();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disaAktar() async {
    setState(() => _busy = true);
    try {
      final path = await _db.disaAktarDb();
      await Share.shareXFiles([XFile(path)], text: 'adet_takip.db yedeği');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dışa aktarıldı:\n$path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profil', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF1E1E22),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Normal Döngü', style: TextStyle(color: Colors.white)),
                  value: 'normal',
                  groupValue: _profil,
                  activeColor: const Color(0xFFFF6F91),
                  onChanged: (v) async {
                    if (v == null) return;
                    await _db.setProfil(v);
                    setState(() => _profil = v);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('PCOS / PMOS', style: TextStyle(color: Colors.white)),
                  value: 'pcos',
                  groupValue: _profil,
                  activeColor: const Color(0xFF9C6ADE),
                  onChanged: (v) async {
                    if (v == null) return;
                    await _db.setProfil(v);
                    setState(() => _profil = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Veri Aktarımı (Masaüstü .db)', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF1E1E22),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Color(0xFFFF6F91)),
                  title: const Text('Masaüstü .db dosyasını içe aktar', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('adet_takip.db seç → tüm veriler gelir', style: TextStyle(color: Colors.white54)),
                  onTap: _busy ? null : _iceAktar,
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF2E9E5B)),
                  title: const Text('Yedek al / dışa aktar', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Mevcut veritabanını paylaş', style: TextStyle(color: Colors.white54)),
                  onTap: _busy ? null : _disaAktar,
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: Color(0xFFFF6F91))),
          ],
          const SizedBox(height: 32),
          const Text(
            'Not: Masaüstü uygulamadaki adet_takip.db dosyasını doğrudan seçebilirsin. '
            'Şema aynı olduğu için döngü, ilaç, tahlil ve notların hepsi aktarılır.',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
