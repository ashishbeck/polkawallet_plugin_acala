import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/api/types/txLiquidityData.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/pages/earn/LPStakePage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnPage extends StatefulWidget {
  EarnPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn';

  @override
  _EarnPageState createState() => _EarnPageState();
}

class _EarnPageState extends State<EarnPage> {
  String _tab = 'aUSD-DOT';

  Timer _timer;

  Future<void> _fetchData() async {
    if (widget.plugin.store.earn.dexPools.length == 0) {
      await widget.plugin.service.earn.getDexPools();
    }
    await Future.wait([
      widget.plugin.service.earn.queryDexPoolInfo(_tab),
      widget.plugin.service.earn
          .queryDexPoolRewards(widget.plugin.store.earn.dexPools),
    ]);

    if (_timer != null) {
      _timer.cancel();
    }
    _timer = Timer(Duration(seconds: 10), () {
      _fetchData();
    });
  }

  Future<void> _onStake() async {
    Navigator.of(context).pushNamed(
      LPStakePage.route,
      arguments: LPStakePageParams(_tab, LPStakePage.actionStake),
    );
  }

  Future<void> _onUnStake() async {
    Navigator.of(context).pushNamed(
      LPStakePage.route,
      arguments: LPStakePageParams(_tab, LPStakePage.actionUnStake),
    );
  }

  Future<void> _onWithdrawReward(LPRewardData reward) async {
    final symbol = widget.plugin.networkState.tokenSymbol[0];
    final incentiveReward = Fmt.priceFloor(reward.incentive, lengthFixed: 4);
    final savingReward = Fmt.priceFloor(reward.saving, lengthFixed: 4);
    final pool = jsonEncode(_tab.toUpperCase().split('-'));

    if (reward.saving > 0 && reward.incentive > 0) {
      final params = [
        'api.tx.incentives.claimRewards({DexIncentive: {DEXShare: $pool}})',
        'api.tx.incentives.claimRewards({DexSaving: {DEXShare: $pool}})',
      ];
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'utility',
            call: 'batch',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.get'],
            txDisplay: {
              "poolId": _tab,
              "incentiveReward": '$incentiveReward $symbol',
              "savingReward": '$savingReward $acala_stable_coin_view',
            },
            params: [],
            rawParams: '[[${params.join(',')}]]',
          ))) as Map;
      if (res != null) {
        res['time'] = DateTime.now().millisecondsSinceEpoch;
        final tx1 = {
          'hash': res['hash'],
          'time': res['time'],
          'action': TxDexLiquidityData.actionRewardIncentive,
          'params': [_tab, incentiveReward, '']
        };
        final tx2 = {
          'hash': res['hash'],
          'time': res['time'],
          'action': TxDexLiquidityData.actionRewardSaving,
          'params': [_tab, '', savingReward]
        };

        widget.plugin.store.earn
            .addDexLiquidityTx(tx1, widget.keyring.current.pubKey);
        widget.plugin.store.earn
            .addDexLiquidityTx(tx2, widget.keyring.current.pubKey);
      }
    } else if (reward.incentive > 0) {
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'incentives',
            call: 'claimRewards',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.get'],
            txDisplay: {
              "poolId": _tab,
              "incentiveReward": '$incentiveReward $symbol',
            },
            params: [],
            rawParams: '[{DexIncentive: {DEXShare: $pool}}]',
          ))) as Map;
      if (res != null) {
        res['time'] = DateTime.now().millisecondsSinceEpoch;
        res['action'] = TxDexLiquidityData.actionRewardIncentive;
        res['params'] = [_tab, incentiveReward, ''];
        widget.plugin.store.earn
            .addDexLiquidityTx(res, widget.keyring.current.pubKey);
      }
    } else if (reward.saving > 0) {
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'incentives',
            call: 'claimRewards',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.get'],
            txDisplay: {
              "poolId": _tab,
              "savingReward": '$savingReward $acala_stable_coin_view',
            },
            params: [],
            rawParams: '[{DexSaving: {DEXShare: $pool}}]',
          ))) as Map;
      if (res != null) {
        res['time'] = DateTime.now().millisecondsSinceEpoch;
        res['action'] = TxDexLiquidityData.actionRewardSaving;
        res['params'] = [_tab, '', savingReward];
        widget.plugin.store.earn
            .addDexLiquidityTx(res, widget.keyring.current.pubKey);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final symbols = widget.plugin.networkState.tokenSymbol;
    final decimals = widget.plugin.networkState.tokenDecimals;
    final pair = _tab.toUpperCase().split('-');
    final stableCoinIndex = pair.indexOf(acala_stable_coin);
    final stableCoinDecimals = decimals[symbols.indexOf(acala_stable_coin)];
    final tokenDecimals =
        decimals[symbols.indexOf(stableCoinIndex == 0 ? pair[1] : pair[0])];
    final leftDecimal =
        stableCoinIndex == 0 ? stableCoinDecimals : tokenDecimals;
    final rightDecimal =
        stableCoinIndex == 0 ? tokenDecimals : stableCoinDecimals;
    final shareDecimals = stableCoinDecimals >= tokenDecimals
        ? stableCoinDecimals
        : tokenDecimals;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['earn.title']),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Theme.of(context).cardColor),
            onPressed: () => Navigator.of(context)
                .pushNamed(EarnHistoryPage.route, arguments: _tab),
          )
        ],
      ),
      body: Observer(
        builder: (_) {
          BigInt issuance = BigInt.zero;
          BigInt shareTotal = BigInt.zero;
          BigInt share = BigInt.zero;
          double stakeShare = 0;
          double poolShare = 0;
          double reward = 0;
          double rewardSaving = 0;

          String lpAmountString = '~';

          DexPoolInfoData poolInfo =
              widget.plugin.store.earn.dexPoolInfoMap[_tab];
          if (poolInfo != null) {
            issuance = poolInfo.issuance;
            shareTotal = poolInfo.sharesTotal;
            share = poolInfo.shares;
            stakeShare = share / shareTotal;
            poolShare = share / issuance;

            final lpAmount =
                Fmt.bigIntToDouble(poolInfo.amountLeft, leftDecimal) *
                    poolShare;
            final lpAmount2 =
                Fmt.bigIntToDouble(poolInfo.amountRight, rightDecimal) *
                    poolShare;
            final pair = _tab.split('-');
            lpAmountString =
                '${Fmt.priceFloor(lpAmount)} ${PluginFmt.tokenView(pair[0])} + ${Fmt.priceFloor(lpAmount2, lengthFixed: 4)} ${PluginFmt.tokenView(pair[1])}';
            reward = (widget.plugin.store.earn.swapPoolRewards[_tab] ?? 0) *
                stakeShare;
            rewardSaving =
                (widget.plugin.store.earn.swapPoolSavingRewards[_tab] ?? 0) *
                    stakeShare;
          }

          final balance = Fmt.balanceInt(widget.plugin.store.assets
                  .tokenBalanceMap[_tab.toUpperCase()]?.amount ??
              '0');

          Color cardColor = Theme.of(context).cardColor;
          Color primaryColor = Theme.of(context).primaryColor;

          return SafeArea(
            child: Column(
              children: <Widget>[
                CurrencySelector(
                  token: _tab,
                  tokenOptions: widget.plugin.store.earn.dexPools
                      .map((e) => e.tokens.map((e) => e['token']).join('-'))
                      .toList(),
                  tokenIcons: widget.plugin.tokenIcons,
                  onSelect: (res) {
                    setState(() {
                      _tab = res;
                    });
                    widget.plugin.service.earn.queryDexPoolInfo(_tab);
                  },
                ),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      _SystemCard(
                        token: _tab,
                        total: Fmt.bigIntToDouble(
                            poolInfo?.sharesTotal ?? BigInt.zero,
                            shareDecimals),
                        userStaked: Fmt.bigIntToDouble(
                            poolInfo?.shares ?? BigInt.zero, shareDecimals),
                        lpAmountString: lpAmountString,
                        actions: Row(
                          children: [
                            Expanded(
                              child: RoundedButton(
                                color: Colors.blue,
                                text: dic['earn.stake'],
                                onPressed:
                                    balance > BigInt.zero ? _onStake : null,
                              ),
                            ),
                            (poolInfo?.shares ?? BigInt.zero) > BigInt.zero
                                ? Container(width: 16)
                                : Container(),
                            (poolInfo?.shares ?? BigInt.zero) > BigInt.zero
                                ? Expanded(
                                    child: RoundedButton(
                                      text: dic['earn.unStake'],
                                      onPressed: _onUnStake,
                                    ),
                                  )
                                : Container()
                          ],
                        ),
                      ),
                      _UserCard(
                        share: stakeShare,
                        poolInfo: poolInfo,
                        token: _tab,
                        rewardEstimate: reward,
                        rewardSavingEstimate: rewardSaving,
                        fee: widget.plugin.service.earn.getSwapFee(),
                        onWithdrawReward: () =>
                            _onWithdrawReward(poolInfo.reward),
                      )
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        color: Colors.blue,
                        child: FlatButton(
                            padding: EdgeInsets.only(top: 16, bottom: 16),
                            child: Text(
                              dic['earn.deposit'],
                              style: TextStyle(color: cardColor),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AddLiquidityPage.route,
                                arguments: _tab,
                              );
                            }),
                      ),
                    ),
                    balance > BigInt.zero
                        ? Expanded(
                            child: Container(
                              color: primaryColor,
                              child: FlatButton(
                                padding: EdgeInsets.only(top: 16, bottom: 16),
                                child: Text(
                                  dic['earn.withdraw'],
                                  style: TextStyle(color: cardColor),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                  WithdrawLiquidityPage.route,
                                  arguments: _tab,
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  _SystemCard({
    this.token,
    this.total,
    this.userStaked,
    this.lpAmountString,
    this.actions,
  });
  final String token;
  final double total;
  final double userStaked;
  final String lpAmountString;
  final Widget actions;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final primary = Theme.of(context).primaryColor;
    final TextStyle primaryText = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: primary,
    );
    return RoundedCard(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Text('${dic['earn.staked']} ${PluginFmt.tokenView(token)}'),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(Fmt.priceFloor(userStaked, lengthFixed: 4),
                    style: primaryText),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '≈ $lpAmountString',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Row(
            children: <Widget>[
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: dic['earn.pool'],
                content: Fmt.priceFloor(total, lengthFixed: 4),
              ),
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: dic['earn.share'],
                content: Fmt.ratio(userStaked / total),
              ),
            ],
          ),
          Divider(height: 24),
          actions
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  _UserCard({
    this.share,
    this.poolInfo,
    this.token,
    this.rewardEstimate,
    this.rewardSavingEstimate,
    this.fee,
    this.onWithdrawReward,
  });
  final double share;
  final DexPoolInfoData poolInfo;
  final String token;
  final double rewardEstimate;
  final double rewardSavingEstimate;
  final double fee;
  final Function onWithdrawReward;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    var reward = poolInfo?.reward?.incentive ?? 0;
    var rewardSaving = poolInfo?.reward?.saving ?? 0;
    if (reward < 0) {
      reward = 0;
    }
    if (rewardSaving < 0) {
      rewardSaving = 0;
    }

    final Color primary = Theme.of(context).primaryColor;
    final TextStyle primaryText = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: primary,
    );

    final canClaim = reward > 0 || rewardSaving > 0;

    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: EdgeInsets.all(16),
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(dic['earn.reward']),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text('${dic['earn.incentive']} (ACA)'),
                      Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(Fmt.priceFloor(reward, lengthFixed: 4),
                            style: primaryText),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text('${dic['earn.saving']} (aUSD)'),
                      Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                            Fmt.priceFloor(rewardSaving, lengthFixed: 4),
                            style: primaryText),
                      ),
                    ],
                  )
                ],
              ),
              rewardEstimate > 0
                  ? Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${dic['earn.incentive']} ≈ ${Fmt.priceFloor(rewardEstimate, lengthMax: 6)} ACA / day',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  : Container(),
              rewardSavingEstimate > 0
                  ? Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${dic['earn.saving']} ≈ ${Fmt.priceFloor(rewardSavingEstimate)} aUSD / day',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  : Container(),
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '${dic['earn.fee']} ${Fmt.ratio(fee)}',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              canClaim
                  ? RoundedButton(
                      text: dic['earn.claim'],
                      onPressed: onWithdrawReward,
                    )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }
}
