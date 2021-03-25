import 'package:polkawallet_ui/utils/format.dart';

class TxDexLiquidityData extends _TxDexLiquidityData {
  static const String actionDeposit = 'deposit';
  static const String actionWithdraw = 'withdraw';
  static const String actionRewardIncentive = 'rewardIncentive';
  static const String actionRewardSaving = 'rewardSaving';
  static const String actionStake = 'stake';
  static const String actionUnStake = 'unStake';
  static TxDexLiquidityData fromJson(Map<String, dynamic> json) {
    TxDexLiquidityData data = TxDexLiquidityData();
    data.hash = json['hash'];
    data.action = json['action'];
    data.currencyId = json['params'][0];
    switch (data.action) {
      case actionDeposit:
        data.amountLeft = Fmt.balanceInt(json['params'][1]);
        data.amountRight = Fmt.balanceInt(json['params'][2]);
        break;
      case actionWithdraw:
        data.amountShare = Fmt.balanceInt(json['params'][1]);
        break;
      case actionRewardIncentive:
        data.amountReward = json['params'][1];
        break;
      case actionRewardSaving:
        data.amountReward = json['params'][2];
        break;
      case actionStake:
      case actionUnStake:
        data.amountShare = Fmt.balanceInt(json['params'][1]);
        break;
    }
    data.time = DateTime.fromMillisecondsSinceEpoch(json['time']);
    return data;
  }
}

abstract class _TxDexLiquidityData {
  String hash;
  String currencyId;
  String action;
  String amountReward;
  BigInt amountLeft;
  BigInt amountRight;
  BigInt amountShare;
  DateTime time;
}
