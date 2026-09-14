/// Masaüstü uygulamadaki predict() mantığının Flutter karşılığı.
class PredictionResult {
  final bool varMi;
  final bool yetersizVeri;
  final String profil;
  final DateTime? sonrakiBaslangic;
  final DateTime? sonrakiMin;
  final DateTime? sonrakiMax;
  final DateTime? ovulasyon;
  final DateTime? dogurganBaslangic;
  final DateTime? dogurganBitis;
  final double? ortDongu;
  final double? ortKanama;
  final String? guven;
  final String? uyari;

  PredictionResult({
    required this.varMi,
    this.yetersizVeri = false,
    this.profil = 'normal',
    this.sonrakiBaslangic,
    this.sonrakiMin,
    this.sonrakiMax,
    this.ovulasyon,
    this.dogurganBaslangic,
    this.dogurganBitis,
    this.ortDongu,
    this.ortKanama,
    this.guven,
    this.uyari,
  });
}

DateTime? _parse(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

List<int> _cycleLengths(List<Map<String, dynamic>> donguler) {
  final starts = donguler
      .map((d) => _parse(d['baslangic'] as String?))
      .whereType<DateTime>()
      .toList()
    ..sort();
  final lengths = <int>[];
  for (var i = 1; i < starts.length; i++) {
    lengths.add(starts[i].difference(starts[i - 1]).inDays);
  }
  return lengths;
}

List<int> _bleedingLengths(List<Map<String, dynamic>> donguler) {
  final out = <int>[];
  for (final d in donguler) {
    final a = _parse(d['baslangic'] as String?);
    final b = _parse(d['bitis'] as String?);
    if (a != null && b != null) {
      out.add(b.difference(a).inDays + 1);
    }
  }
  return out;
}

PredictionResult predict(List<Map<String, dynamic>> donguler, String profil) {
  final starts = donguler
      .map((d) => _parse(d['baslangic'] as String?))
      .whereType<DateTime>()
      .toList()
    ..sort();

  if (starts.isEmpty) {
    return PredictionResult(varMi: false);
  }

  final lengths = _cycleLengths(donguler);
  final bleed = _bleedingLengths(donguler);
  final ortKanama = bleed.isEmpty ? null : bleed.reduce((a, b) => a + b) / bleed.length;
  final anovSayisi = donguler.where((d) => (d['anovulatuar'] as int? ?? 0) == 1).length;
  final lastStart = starts.last;

  if (lengths.isEmpty) {
    return PredictionResult(
      varMi: true,
      yetersizVeri: true,
      ortKanama: ortKanama,
      uyari: 'Güvenilir tahmin için en az 2 döngü (2 başlangıç tarihi) gerekiyor.',
    );
  }

  final ortDongu = lengths.reduce((a, b) => a + b) / lengths.length;

  if (profil == 'pcos') {
    final minLen = lengths.reduce((a, b) => a < b ? a : b);
    final maxLen = lengths.reduce((a, b) => a > b ? a : b);
    final sonrakiMin = lastStart.add(Duration(days: minLen));
    final sonrakiMax = lastStart.add(Duration(days: maxLen));

    final uyariParts = <String>[];
    if (anovSayisi > 0) {
      uyariParts.add('Geçmişte $anovSayisi anovulatuar (ovulasyonsuz) döngü kaydedilmiş.');
    }
    if ((maxLen - minLen) > 10) {
      uyariParts.add('Döngü uzunlukları değişken; tek gün yerine ARALIK olarak değerlendirin.');
    }
    if (uyariParts.isEmpty) {
      uyariParts.add('PCOS/PMOS modunda tahminler geniş aralıklıdır, kesin gün verilmez.');
    }

    return PredictionResult(
      varMi: true,
      profil: 'pcos',
      sonrakiMin: sonrakiMin,
      sonrakiMax: sonrakiMax,
      ortDongu: ortDongu,
      ortKanama: ortKanama,
      guven: 'dusuk',
      uyari: uyariParts.join(' '),
    );
  } else {
    final sonrakiBaslangic = lastStart.add(Duration(days: ortDongu.round()));
    final ovulasyon = sonrakiBaslangic.subtract(const Duration(days: 14));
    final dogurganBaslangic = ovulasyon.subtract(const Duration(days: 5));
    final dogurganBitis = ovulasyon.add(const Duration(days: 1));
    final tutarlilik = lengths.length >= 2
        ? (lengths.reduce((a, b) => a > b ? a : b) - lengths.reduce((a, b) => a < b ? a : b))
        : 0;
    final guven = (lengths.length >= 3 && tutarlilik <= 5) ? 'yuksek' : 'orta';

    return PredictionResult(
      varMi: true,
      profil: 'normal',
      sonrakiBaslangic: sonrakiBaslangic,
      ovulasyon: ovulasyon,
      dogurganBaslangic: dogurganBaslangic,
      dogurganBitis: dogurganBitis,
      ortDongu: ortDongu,
      ortKanama: ortKanama,
      guven: guven,
    );
  }
}

/// Döngünün hangi gününde olduğumuzu hesaplar (1-indexed).
int? cycleDay(List<Map<String, dynamic>> donguler) {
  final starts = donguler
      .map((d) => _parse(d['baslangic'] as String?))
      .whereType<DateTime>()
      .toList()
    ..sort();
  if (starts.isEmpty) return null;
  final last = starts.last;
  final today = DateTime.now();
  final day = today.difference(DateTime(last.year, last.month, last.day)).inDays + 1;
  return day < 1 ? null : day;
}
