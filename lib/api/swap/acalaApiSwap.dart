import 'package:polkawallet_plugin_acala/api/swap/acalaServiceSwap.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/api/types/swapOutputData.dart';

class AcalaApiSwap {
  AcalaApiSwap(this.service);

  final AcalaServiceSwap service;

  Future<SwapOutputData> queryTokenSwapAmount(
    String supplyAmount,
    String targetAmount,
    List<String> swapPair,
    String slippage,
  ) async {
    final output = await service.queryTokenSwapAmount(
        supplyAmount, targetAmount, swapPair, slippage);
    return SwapOutputData.fromJson(output);
  }

  Future<List<List>> getTokenPairs() async {
    return await service.getTokenPairs();
  }

  Future<Map> queryDexLiquidityPoolRewards(List<List> dexPools) async {
    return await service.queryDexLiquidityPoolRewards(dexPools);
  }

  Future<Map<String, DexPoolInfoData>> queryDexPoolInfo(
      String pool, address) async {
    final Map info = await service.queryDexPoolInfo(pool, address);
    return {pool: DexPoolInfoData.fromJson(Map<String, dynamic>.of(info))};
  }
}
