// Monte-Carlo sanity check for the SlotEngine RTP in debug mode.
//
// The release build targets ~98% RTP but we deliberately bias the dev build
// to feel "very generous". The user asked for ~120% RTP across 10 000 spins
// so this test prints the measured RTP and asserts a plausible range.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:amazy_zone/game/slot_engine.dart';
import 'package:amazy_zone/game/spin_result.dart';

const Map<BonusTier, double> _avgWheelMultiplier = <BonusTier, double>{
  BonusTier.none: 0.0,
  // Bronze: 1,2,3,2,5,3,1,8 — avg 3.125x.
  BonusTier.bronze: 3.125,
  // Silver: 6,10,16,8,25,12,20,50 — avg 18.375x.
  BonusTier.silver: 18.375,
  // Gold: 25,50,75,40,120,60,150,820 — avg 167.5x.
  BonusTier.gold: 167.5,
};

double _measureRtp(SlotEngine engine, int spins, {double totalBet = 1.0}) {
  double totalPay = 0;
  for (int i = 0; i < spins; i++) {
    final SpinResult r = engine.spin(totalBet: totalBet);
    double spinPay = r.totalPay;
    if (r.bonusTier != BonusTier.none) {
      spinPay += totalBet * _avgWheelMultiplier[r.bonusTier]!;
    }
    totalPay += spinPay;
  }
  return totalPay / (totalBet * spins);
}

void main() {
  test('Engine RTP ≈ 98% over 10 000 spins (multi-seed average)', () {
    const double totalBet = 1.0;
    const int spins = 10000;
    const List<int> seeds = <int>[7, 42, 2026, 1337, 55555];

    final List<double> rtps = <double>[];
    for (final int seed in seeds) {
      final SlotEngine engine =
          SlotEngine(random: Random(seed), debugBoost: false);
      final double rtp = _measureRtp(engine, spins, totalBet: totalBet);
      rtps.add(rtp);
      // ignore: avoid_print
      print('  seed=$seed  rtp=${(rtp * 100).toStringAsFixed(2)}%');
    }

    final double avg = rtps.reduce((double a, double b) => a + b) / rtps.length;
    // ignore: avoid_print
    print('[Average RTP] ${(avg * 100).toStringAsFixed(2)}%  '
        'across ${seeds.length} runs × $spins spins');

    // Gold hits are 0.5% and swing a single 10k sample. The average across
    // seeds should sit near the advertised 98%.
    expect(avg, greaterThan(0.85));
    expect(avg, lessThan(1.15));
  });

  test('Line-hit frequency stays casino-like', () {
    final SlotEngine engine =
        SlotEngine(random: Random(123), debugBoost: false);
    const int spins = 10000;
    int lineWins = 0;
    int bonusHits = 0;
    for (int i = 0; i < spins; i++) {
      final SpinResult r = engine.spin(totalBet: 1.0);
      if (r.lineWins.isNotEmpty) lineWins++;
      if (r.bonusTier != BonusTier.none) bonusHits++;
    }
    final double hit = lineWins / spins;
    final double bonus = bonusHits / spins;
    // ignore: avoid_print
    print('[Hit freq] line=${(hit * 100).toStringAsFixed(2)}%  '
        'bonus=${(bonus * 100).toStringAsFixed(2)}%');
    expect(hit, greaterThan(0.01));
    expect(hit, lessThan(0.45));
    // 3+4+5 scatters = 2.25%.
    expect(bonus, greaterThan(0.010));
    expect(bonus, lessThan(0.040));
  });

  test('Scatter counts match the configured ladder', () {
    // Verify precise P(3/4/5 scatters) across a large sample.
    final SlotEngine engine =
        SlotEngine(random: Random(99), debugBoost: false);
    const int spins = 100000;
    int c0 = 0, c2 = 0, c3 = 0, c4 = 0, c5 = 0;
    for (int i = 0; i < spins; i++) {
      final SpinResult r = engine.spin(totalBet: 1.0);
      switch (r.scatterCount) {
        case 0:
          c0++;
          break;
        case 2:
          c2++;
          break;
        case 3:
          c3++;
          break;
        case 4:
          c4++;
          break;
        case 5:
          c5++;
          break;
      }
    }
    // ignore: avoid_print
    print('[Scatter counts over $spins spins] '
        '0=${(c0 / spins * 100).toStringAsFixed(3)}%  '
        '2=${(c2 / spins * 100).toStringAsFixed(3)}%  '
        '3=${(c3 / spins * 100).toStringAsFixed(3)}%  '
        '4=${(c4 / spins * 100).toStringAsFixed(3)}%  '
        '5=${(c5 / spins * 100).toStringAsFixed(3)}%');
    // P(3)=1.00%, P(4)=0.75%, P(5)=0.50%.
    expect(c3 / spins, closeTo(0.0100, 0.002));
    expect(c4 / spins, closeTo(0.0075, 0.002));
    expect(c5 / spins, closeTo(0.0050, 0.0015));
    expect(c2 / spins, closeTo(0.0200, 0.004));
  });
}
