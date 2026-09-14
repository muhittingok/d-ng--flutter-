import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';

/// Masaüstü uygulamadaki adet_takip.db şemasıyla birebir uyumlu.
/// Böylece .db dosyasını doğrudan kopyalayıp kullanabilirsin.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('adet_takip.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, fileName);
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayarlar (
        anahtar TEXT PRIMARY KEY,
        deger TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS donguler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        baslangic TEXT NOT NULL,
        bitis TEXT,
        anovulatuar INTEGER DEFAULT 0,
        notlar TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ilaclar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ad TEXT NOT NULL,
        tarih TEXT NOT NULL,
        bitis TEXT,
        doz TEXT DEFAULT '',
        not_ TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gunluk_notlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarih TEXT NOT NULL,
        not_ TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tahliller (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_adi TEXT NOT NULL,
        tarih TEXT NOT NULL,
        deger REAL,
        deger_metin TEXT,
        birim TEXT DEFAULT '',
        ref_alt REAL,
        ref_ust REAL,
        laboratuvar TEXT DEFAULT '',
        gorsel_yolu TEXT DEFAULT '',
        adet_durumu TEXT DEFAULT 'bilinmiyor'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // İleride şema değişiklikleri için
  }

  // ---------- Ayarlar ----------
  Future<String?> getAyar(String key) async {
    final db = await database;
    final rows = await db.query('ayarlar', where: 'anahtar = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['deger'] as String?;
  }

  Future<void> setAyar(String key, String value) async {
    final db = await database;
    await db.insert(
      'ayarlar',
      {'anahtar': key, 'deger': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> getProfil() async {
    return await getAyar('profil') ?? 'normal';
  }

  Future<void> setProfil(String profil) async {
    await setAyar('profil', profil);
  }

  // ---------- Döngüler ----------
  Future<List<Map<String, dynamic>>> dongulerListele() async {
    final db = await database;
    return db.query('donguler', orderBy: 'baslangic ASC');
  }

  Future<int> donguEkle({
    required String baslangic,
    String? bitis,
    bool anovulatuar = false,
    String notlar = '',
  }) async {
    final db = await database;
    return db.insert('donguler', {
      'baslangic': baslangic,
      'bitis': bitis,
      'anovulatuar': anovulatuar ? 1 : 0,
      'notlar': notlar,
    });
  }

  Future<void> donguGuncelle(int id, {
    required String baslangic,
    String? bitis,
    bool anovulatuar = false,
    String notlar = '',
  }) async {
    final db = await database;
    await db.update(
      'donguler',
      {
        'baslangic': baslangic,
        'bitis': bitis,
        'anovulatuar': anovulatuar ? 1 : 0,
        'notlar': notlar,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> donguBitir(int id, String bitis) async {
    final db = await database;
    await db.update('donguler', {'bitis': bitis}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> donguSil(int id) async {
    final db = await database;
    await db.delete('donguler', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- İlaçlar ----------
  Future<List<Map<String, dynamic>>> ilaclarListele() async {
    final db = await database;
    return db.query('ilaclar', orderBy: 'tarih DESC');
  }

  Future<int> ilacEkle({
    required String ad,
    required String tarih,
    String? bitis,
    String doz = '',
    String not_ = '',
  }) async {
    final db = await database;
    return db.insert('ilaclar', {
      'ad': ad,
      'tarih': tarih,
      'bitis': bitis,
      'doz': doz,
      'not_': not_,
    });
  }

  Future<void> ilacSil(int id) async {
    final db = await database;
    await db.delete('ilaclar', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Günlük notlar ----------
  Future<List<Map<String, dynamic>>> notlarListele() async {
    final db = await database;
    return db.query('gunluk_notlar', orderBy: 'tarih DESC');
  }

  Future<int> notEkle(String tarih, String not_) async {
    final db = await database;
    return db.insert('gunluk_notlar', {'tarih': tarih, 'not_': not_});
  }

  Future<void> notSil(int id) async {
    final db = await database;
    await db.delete('gunluk_notlar', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Tahliller ----------
  Future<List<Map<String, dynamic>>> tahlillerListele() async {
    final db = await database;
    return db.query('tahliller', orderBy: 'test_adi ASC, tarih ASC');
  }

  Future<int> tahlilEkle(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('tahliller', data);
  }

  Future<void> tahlilSil(int id) async {
    final db = await database;
    await db.delete('tahliller', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- .db İçe / Dışa Aktarma ----------
  /// Masaüstü uygulamadan alınan adet_takip.db dosyasını içe aktarır.
  Future<String> iceAktarDb() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) {
      throw Exception('Dosya seçilmedi');
    }

    final sourcePath = result.files.single.path!;
    if (!sourcePath.toLowerCase().endsWith('.db')) {
      throw Exception('Lütfen .db uzantılı dosya seçin');
    }

    // Mevcut bağlantıyı kapat
    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    final dir = await getApplicationDocumentsDirectory();
    final targetPath = join(dir.path, 'adet_takip.db');

    // Yedek al
    final backupPath = join(dir.path, 'adet_takip_yedek_${DateTime.now().millisecondsSinceEpoch}.db');
    final current = File(targetPath);
    if (await current.exists()) {
      await current.copy(backupPath);
    }

    // Yeni db'yi kopyala
    await File(sourcePath).copy(targetPath);

    // Yeniden aç
    _db = await _initDB('adet_takip.db');
    return 'Veritabanı başarıyla içe aktarıldı.';
  }

  /// Mevcut veritabanını paylaşılabilir konuma kopyalar.
  Future<String> disaAktarDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final sourcePath = join(dir.path, 'adet_takip.db');
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('Henüz veritabanı oluşmamış');
    }

    final exportDir = await getExternalStorageDirectory() ?? dir;
    final exportPath = join(
      exportDir.path,
      'adet_takip_export_${DateTime.now().toIso8601String().substring(0, 10)}.db',
    );
    await source.copy(exportPath);
    return exportPath;
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
