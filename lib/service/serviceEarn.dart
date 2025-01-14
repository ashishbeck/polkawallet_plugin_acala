import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceEarn {
  ServiceEarn(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginAcala plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  Map<String, double> _calcIncentives(Map rewards) {
    final blockTime = plugin.networkConst['babe'] == null
        ? BLOCK_TIME_DEFAULT
        : int.parse(plugin.networkConst['babe']['expectedBlockTime']);
    final epoch =
        int.parse(plugin.networkConst['incentives']['accumulatePeriod']);
    final epochOfDay = SECONDS_OF_DAY * 1000 / blockTime / epoch;
    final res = Map<String, double>();
    rewards.forEach((k, v) {
      res[k] = Fmt.balanceDouble(
              v.toString(), plugin.networkState.tokenDecimals[0]) *
          epochOfDay;
    });
    return res;
  }

  Map<String, double> _calcSavingRates(Map savingRates) {
    final blockTime = plugin.networkConst['babe'] == null
        ? BLOCK_TIME_DEFAULT
        : int.parse(plugin.networkConst['babe']['expectedBlockTime']);
    final epoch =
        int.parse(plugin.networkConst['incentives']['accumulatePeriod']);
    final epochOfYear = SECONDS_OF_YEAR * 1000 / blockTime / epoch;
    final res = Map<String, double>();
    savingRates.forEach((k, v) {
      res[k] = Fmt.balanceDouble(
              v.toString(), plugin.networkState.tokenDecimals[0]) *
          epochOfYear;
    });
    return res;
  }

  Future<List<DexPoolData>> getDexPools() async {
    final pools = await api.swap.getTokenPairs();
    store.earn.setDexPools(pools);
    return pools;
  }

  Future<List<DexPoolData>> getBootstraps() async {
    final pools = await api.swap.getBootstraps();
    store.earn.setBootstraps(pools);
    return pools;
  }

  Future<void> queryDexPoolRewards(List<DexPoolData> pools) async {
    final rewards = await api.swap.queryDexLiquidityPoolRewards(pools);
    final res = Map<String, Map<String, double>>();
    res['incentives'] = _calcIncentives(rewards['incentives']);
    res['savingRates'] = _calcSavingRates(rewards['savingRates']);
    store.earn.setDexPoolRewards(res);
  }

  Future<void> queryDexPoolInfo(String poolId) async {
    final info =
        await api.swap.queryDexPoolInfo(poolId, keyring.current.address);
    store.earn.setDexPoolInfo(info);
  }

  double getSwapFee() {
    return plugin.networkConst['dex']['getExchangeFee'][0] /
        plugin.networkConst['dex']['getExchangeFee'][1];
  }
}
