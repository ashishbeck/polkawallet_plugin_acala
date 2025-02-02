import 'package:polkawallet_plugin_acala/common/constants/index.dart';

class PluginFmt {
  static String tokenView(String token) {
    String tokenView = token ?? '';
    if (token == acala_stable_coin) {
      tokenView = acala_stable_coin_view;
    }
    if (token == karura_stable_coin) {
      tokenView = karura_stable_coin_view;
    }
    if (token == acala_token_ren_btc) {
      tokenView = acala_token_ren_btc_view;
    }
    if (token == acala_token_polka_btc) {
      tokenView = acala_token_polka_btc_view;
    }
    if (token.contains('-')) {
      tokenView =
          '${token.split('-').map((e) => PluginFmt.tokenView(e)).join('-')} LP';
    }
    return tokenView;
  }

  static LiquidityShareInfo calcLiquidityShare(
      List<double> pool, List<double> user) {
    final isPoolLeftZero = pool[0] == 0.0;
    final isPoolRightZero = pool[1] == 0.0;
    final xRate = isPoolRightZero ? 0 : pool[0] / pool[1];
    final totalShare =
        isPoolLeftZero ? (pool[1] * 2) : pool[0] + pool[1] * xRate;

    final userShare =
        isPoolLeftZero ? (user[1] * 2) : user[0] + user[1] * xRate;
    return LiquidityShareInfo(userShare, userShare / totalShare);
  }
}

class LiquidityShareInfo {
  LiquidityShareInfo(this.lp, this.ratio);
  final double lp;
  final double ratio;
}
