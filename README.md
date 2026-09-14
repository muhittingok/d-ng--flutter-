# PCOS / Menstrüasyon Takip — Flutter

Masaüstü (PySide6) uygulamanın mobil karşılığı.

## Özellikler

- Dairesel döngü halkası (Flo tarzı)
- Normal / PCOS-PMOS profili
- Döngü, ilaç, tahlil, günlük not takibi
- **Masaüstü `adet_takip.db` dosyasını doğrudan içe aktarma**
- Tamamen offline (SQLite)

## Kurulum (APK üretmek için)

1. [Flutter](https://docs.flutter.dev/get-started/install) kur (3.16+)
2. Bu klasörde:
   ```bash
   flutter pub get
   flutter run          # cihazda / emülatörde dene
   flutter build apk    # APK üret → build/app/outputs/flutter-apk/app-release.apk
   ```

## Masaüstü verisini aktarma

1. Masaüstü uygulamadaki `adet_takip.db` dosyasını telefona kopyala
2. Mobil uygulamada **Ayarlar → Masaüstü .db dosyasını içe aktar**
3. Dosyayı seç → tüm veriler gelir

## Klasör yapısı

```
lib/
  main.dart
  db/database_helper.dart   ← masaüstü şemasıyla birebir
  services/prediction.dart  ← tahmin mantığı
  widgets/cycle_ring.dart   ← dairesel UI
  screens/
    home_screen.dart
    cycles_screen.dart
    meds_screen.dart
    labs_screen.dart
    notes_screen.dart
    settings_screen.dart
```
