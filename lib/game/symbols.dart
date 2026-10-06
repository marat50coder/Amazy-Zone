import 'package:flutter/foundation.dart';

/// All reel symbols.
enum SlotSymbol {
  ten,
  jack,
  queen,
  king,
  ace,
  cherry,
  bell,
  bar,
  chips,
  diamonds,
  crown,
  amazoncoin,
  wild,
  bonus,
}

/// Static per-symbol data (asset, display tier, weights, payouts).
@immutable
class SymbolData {
  const SymbolData({
    required this.symbol,
    required this.asset,
    required this.weight,
    required this.pay3,
    required this.pay4,
    required this.pay5,
    required this.isHigh,
  });

  final SlotSymbol symbol;
  final String asset;

  /// Weight on each reel strip (same across all 5 reels for simplicity).
  final int weight;

  /// Pays expressed as a multiplier of the bet-per-line.
  final double pay3;
  final double pay4;
  final double pay5;

  /// High-tier (picture) symbols glow differently when they land in a win.
  final bool isHigh;
}

const String _kGpAsset = 'assets/Amazy_Zone_gameplay_assets/';

/// Master registry. Weights are tuned so the theoretical RTP (including the
/// bonus wheel) sits around 98%.
const Map<SlotSymbol, SymbolData> kSymbolRegistry = <SlotSymbol, SymbolData>{
  SlotSymbol.ten: SymbolData(
    symbol: SlotSymbol.ten,
    asset: '${_kGpAsset}10_slot_asset.webp',
    weight: 14,
    pay3: 0.10,
    pay4: 0.30,
    pay5: 1.00,
    isHigh: false,
  ),
  SlotSymbol.jack: SymbolData(
    symbol: SlotSymbol.jack,
    asset: '${_kGpAsset}J_slot_asset.webp',
    weight: 14,
    pay3: 0.10,
    pay4: 0.30,
    pay5: 1.00,
    isHigh: false,
  ),
  SlotSymbol.queen: SymbolData(
    symbol: SlotSymbol.queen,
    asset: '${_kGpAsset}Q_slot_asset.webp',
    weight: 12,
    pay3: 0.15,
    pay4: 0.50,
    pay5: 1.50,
    isHigh: false,
  ),
  SlotSymbol.king: SymbolData(
    symbol: SlotSymbol.king,
    asset: '${_kGpAsset}K_slot_asset.webp',
    weight: 12,
    pay3: 0.15,
    pay4: 0.50,
    pay5: 1.50,
    isHigh: false,
  ),
  SlotSymbol.ace: SymbolData(
    symbol: SlotSymbol.ace,
    asset: '${_kGpAsset}A_slot_asset.webp',
    weight: 10,
    pay3: 0.20,
    pay4: 0.75,
    pay5: 2.00,
    isHigh: false,
  ),
  SlotSymbol.cherry: SymbolData(
    symbol: SlotSymbol.cherry,
    asset: '${_kGpAsset}cherry_slot_asset.webp',
    weight: 8,
    pay3: 0.30,
    pay4: 1.00,
    pay5: 3.00,
    isHigh: true,
  ),
  SlotSymbol.bell: SymbolData(
    symbol: SlotSymbol.bell,
    asset: '${_kGpAsset}bell_slot_asset.webp',
    weight: 7,
    pay3: 0.40,
    pay4: 1.50,
    pay5: 5.00,
    isHigh: true,
  ),
  SlotSymbol.bar: SymbolData(
    symbol: SlotSymbol.bar,
    asset: '${_kGpAsset}BAR_slot_asset.webp',
    weight: 6,
    pay3: 0.50,
    pay4: 2.00,
    pay5: 7.50,
    isHigh: true,
  ),
  SlotSymbol.chips: SymbolData(
    symbol: SlotSymbol.chips,
    asset: '${_kGpAsset}chips_slot_asset.webp',
    weight: 5,
    pay3: 0.80,
    pay4: 3.00,
    pay5: 12.50,
    isHigh: true,
  ),
  SlotSymbol.diamonds: SymbolData(
    symbol: SlotSymbol.diamonds,
    asset: '${_kGpAsset}diamonds_slot_asset.webp',
    weight: 4,
    pay3: 1.00,
    pay4: 5.00,
    pay5: 20.00,
    isHigh: true,
  ),
  SlotSymbol.crown: SymbolData(
    symbol: SlotSymbol.crown,
    asset: '${_kGpAsset}Crown_slot_asset.webp',
    weight: 3,
    pay3: 1.50,
    pay4: 7.50,
    pay5: 30.00,
    isHigh: true,
  ),
  SlotSymbol.amazoncoin: SymbolData(
    symbol: SlotSymbol.amazoncoin,
    asset: '${_kGpAsset}amazoncoin_slot_asset.webp',
    weight: 2,
    pay3: 2.50,
    pay4: 15.00,
    pay5: 75.00,
    isHigh: true,
  ),
  SlotSymbol.wild: SymbolData(
    symbol: SlotSymbol.wild,
    asset: '${_kGpAsset}wild_slot_asset.webp',
    weight: 2,
    pay3: 2.00,
    pay4: 10.00,
    pay5: 50.00,
    isHigh: true,
  ),
  SlotSymbol.bonus: SymbolData(
    symbol: SlotSymbol.bonus,
    asset: '${_kGpAsset}Bonus_slot_asset.webp',
    weight: 1,
    // Scatters do not pay via the paytable; the bonus wheel handles payout.
    pay3: 0.0,
    pay4: 0.0,
    pay5: 0.0,
    isHigh: true,
  ),
};

/// Convenience accessor.
SymbolData symbolData(SlotSymbol s) => kSymbolRegistry[s]!;
