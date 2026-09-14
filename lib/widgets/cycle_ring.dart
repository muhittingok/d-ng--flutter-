import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/prediction.dart';

/// Flo tarzı dairesel döngü halkası.
class CycleRing extends StatelessWidget {
  final PredictionResult prediction;
  final int? gun;
  final String profil;
  final VoidCallback? onTapPhaseInfo;

  const CycleRing({
    super.key,
    required this.prediction,
    this.gun,
    this.profil = 'normal',
    this.onTapPhaseInfo,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = DateFormat('d MMM', 'tr_TR').format(today);

    String mainText;
    String? subText;
    Color phaseColor = const Color(0xFF2EC4B6);

    if (!prediction.varMi) {
      mainText = 'Henüz döngü\nkaydı yok';
      subText = 'İlk adetini ekle';
    } else if (prediction.yetersizVeri) {
      mainText = 'Tahmin için\ndaha fazla veri gerekli';
      subText = prediction.uyari;
    } else if (profil == 'pcos' && prediction.sonrakiMin != null) {
      final minStr = DateFormat('d MMM', 'tr_TR').format(prediction.sonrakiMin!);
      final maxStr = DateFormat('d MMM', 'tr_TR').format(prediction.sonrakiMax!);
      mainText = 'Sonraki âdet\n$minStr – $maxStr';
      subText = 'PCOS aralığı';
      phaseColor = const Color(0xFFFF6F91);
    } else if (prediction.sonrakiBaslangic != null) {
      final nextStr = DateFormat('d MMM', 'tr_TR').format(prediction.sonrakiBaslangic!);
      mainText = 'Sonraki âdetin\n$nextStr günü başlayacak';
      subText = _phaseName(gun);
      phaseColor = _phaseColor(gun);
    } else {
      mainText = 'Veri yetersiz';
    }

    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arka plan halka
          CustomPaint(
            size: const Size(320, 320),
            painter: _RingPainter(
              gun: gun ?? 1,
              ortDongu: prediction.ortDongu ?? 28,
              profil: profil,
            ),
          ),
          // Orta içerik
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bugün, $dateStr',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  mainText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (subText != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onTapPhaseInfo,
                    child: Text(
                      subText,
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Gün rozeti
          if (gun != null)
            Positioned(
              right: 28,
              top: 70,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gün',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    Text(
                      '$gun',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _phaseName(int? gun) {
    if (gun == null) return '';
    if (gun <= 5) return 'Adet evresi hakkında';
    if (gun <= 13) return 'Foliküler evre hakkında';
    if (gun <= 16) return 'Ovulasyon evresi hakkında';
    return 'Luteal evre hakkında';
  }

  Color _phaseColor(int? gun) {
    if (gun == null) return const Color(0xFF2EC4B6);
    if (gun <= 5) return const Color(0xFFFF4D6A);
    if (gun <= 13) return const Color(0xFF2EC4B6);
    if (gun <= 16) return const Color(0xFFFFB703);
    return const Color(0xFF9C6ADE);
  }
}

class _RingPainter extends CustomPainter {
  final int gun;
  final double ortDongu;
  final String profil;

  _RingPainter({
    required this.gun,
    required this.ortDongu,
    required this.profil,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    const stroke = 18.0;

    // Arka plan gri halka
    final bgPaint = Paint()
      ..color = const Color(0xFF3A3A40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final total = ortDongu.clamp(21, 45);
    // Adet fazı (kırmızı) ~5 gün
    final periodSweep = (5 / total) * 2 * math.pi;
    // Foliküler / diğer faz
    final progress = (gun / total).clamp(0.0, 1.0);
    final progressSweep = progress * 2 * math.pi;

    // Kırmızı adet yayı (üstten başlar, saat yönünde)
    final redPaint = Paint()
      ..color = const Color(0xFFFF4D6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      periodSweep,
      false,
      redPaint,
    );

    // İlerleme yayı (teal)
    if (progressSweep > periodSweep) {
      final tealPaint = Paint()
        ..color = const Color(0xFF2EC4B6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + periodSweep,
        progressSweep - periodSweep,
        false,
        tealPaint,
      );
    }

    // Noktalı süs (opsiyonel)
    final dotPaint = Paint()..color = const Color(0xFFFF4D6A);
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + periodSweep + (i * 0.08);
      final x = center.dx + (radius) * math.cos(angle);
      final y = center.dy + (radius) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.gun != gun || old.ortDongu != ortDongu;
}
