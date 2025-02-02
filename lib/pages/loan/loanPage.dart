import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanHistoryPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/MainTabBar.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanPage extends StatefulWidget {
  LoanPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/loan';

  @override
  _LoanPageState createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  int _tab = 0;

  Future<void> _fetchData() async {
    await widget.plugin.service.loan
        .queryLoanTypes(widget.keyring.current.address);
    if (mounted) {
      widget.plugin.service.loan
          .subscribeAccountLoans(widget.keyring.current.address);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isKar = widget.plugin.basic.name == plugin_name_karura;
      final bool enabled = !isKar || ModalRoute.of(context).settings.arguments;
      // final bool enabled = true;
      if (enabled) {
        _fetchData();
      } else {
        widget.plugin.store.loan.setLoansLoading(false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.plugin.service.loan.unsubscribeAccountLoans();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final isKar = widget.plugin.basic.name == plugin_name_karura;
    final bool enabled = !isKar || ModalRoute.of(context).settings.arguments;

    final stableCoinDecimals = widget.plugin.networkState.tokenDecimals[widget
        .plugin.networkState.tokenSymbol
        .indexOf(isKar ? karura_stable_coin : acala_stable_coin)];

    return Observer(
      builder: (_) {
        final loans = widget.plugin.store.loan.loans.values.toList();
        loans.retainWhere((loan) =>
            loan.debits > BigInt.zero || loan.collaterals > BigInt.zero);

        return Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: AppBar(
            title: Text(dic['loan.title']),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.history, color: Theme.of(context).cardColor),
                onPressed: enabled
                    ? () =>
                        Navigator.of(context).pushNamed(LoanHistoryPage.route)
                    : null,
              )
            ],
          ),
          body: SafeArea(
            child: AccountCardLayout(
                widget.keyring.current,
                Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: MainTabBar(
                        fontSize: 20,
                        lineWidth: 6,
                        tabs: [dic['loan.my'], dic['loan.incentive']],
                        activeTab: _tab,
                        onTap: (i) {
                          setState(() {
                            _tab = i;
                          });
                        },
                      ),
                    ),
                    widget.plugin.store.loan.loansLoading
                        ? Container(
                            height: MediaQuery.of(context).size.width / 2,
                            child: CupertinoActivityIndicator(),
                          )
                        : loans.length > 0
                            ? Expanded(
                                child: _tab == 0
                                    ? ListView(
                                        padding: EdgeInsets.all(16),
                                        children: loans.map((loan) {
                                          final tokenDecimals = widget.plugin
                                                  .networkState.tokenDecimals[
                                              widget.plugin.networkState
                                                  .tokenSymbol
                                                  .indexOf(loan.token)];
                                          return LoanOverviewCard(
                                            loan,
                                            stableCoinDecimals,
                                            tokenDecimals,
                                            widget.plugin.tokenIcons,
                                          );
                                        }).toList(),
                                      )
                                    : CollateralIncentiveList(
                                        loans: widget.plugin.store.loan.loans,
                                        tokenIcons: widget.plugin.tokenIcons,
                                        totalCDPs:
                                            widget.plugin.store.loan.totalCDPs,
                                        incentives: widget.plugin.store.loan
                                            .collateralIncentives,
                                        rewards: widget.plugin.store.loan
                                            .collateralRewards,
                                        prices:
                                            widget.plugin.store.assets.prices,
                                        stableCoinDecimals: stableCoinDecimals,
                                        incentiveTokenSymbol: widget
                                            .plugin.networkState.tokenSymbol[0],
                                      ),
                              )
                            : RoundedCard(
                                margin: EdgeInsets.all(16),
                                padding: EdgeInsets.fromLTRB(80, 24, 80, 24),
                                child: SvgPicture.asset(
                                    'packages/polkawallet_plugin_acala/assets/images/loan-start.svg',
                                    color: Theme.of(context).primaryColor),
                              ),
                    !widget.plugin.store.loan.loansLoading
                        ? Container(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: RoundedButton(
                                text: '+ ${dic['loan.borrow']}',
                                onPressed: enabled
                                    ? () {
                                        Navigator.of(context)
                                            .pushNamed(LoanCreatePage.route);
                                      }
                                    : null),
                          )
                        : Container(),
                  ],
                )),
          ),
        );
      },
    );
  }
}

class LoanOverviewCard extends StatelessWidget {
  LoanOverviewCard(this.loan, this.stableCoinDecimals, this.collateralDecimals,
      this.tokenIcons);
  final LoanData loan;
  final int stableCoinDecimals;
  final int collateralDecimals;
  final Map<String, Widget> tokenIcons;

  final colorSafe = Color(0xFFB9F6CA);
  final colorWarn = Color(0xFFFFD180);
  final colorDanger = Color(0xFFFF8A80);

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');

    final requiredCollateralRatio =
        double.parse(Fmt.token(loan.type.requiredCollateralRatio, 18));
    final borrowedRatio = 1 / loan.collateralRatio;

    return GestureDetector(
      child: Stack(children: [
        RoundedCard(
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            height: 176,
            child: LiquidLinearProgressIndicator(
              value: borrowedRatio,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(
                  loan.collateralRatio > requiredCollateralRatio
                      ? loan.collateralRatio > requiredCollateralRatio + 0.2
                          ? colorSafe
                          : colorWarn
                      : colorDanger),
              borderRadius: 16,
              direction: Axis.vertical,
            ),
          ),
        ),
        Container(
          color: Colors.transparent,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 8),
                child: Text(
                    '${dic['loan.collateral']}(${PluginFmt.tokenView(loan.token)})'),
              ),
              Row(children: [
                Container(
                    margin: EdgeInsets.only(right: 8),
                    child: TokenIcon(loan.token, tokenIcons)),
                Text(Fmt.priceFloorBigInt(loan.collaterals, collateralDecimals),
                    style: TextStyle(
                      fontSize: 30,
                      letterSpacing: -0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    )),
              ]),
              Row(children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(dic['loan.borrowed'] + '(aUSD)')),
                    Text(
                      Fmt.priceCeilBigInt(loan.debits, stableCoinDecimals),
                      style: Theme.of(context).textTheme.headline4,
                    )
                  ],
                )),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(dic['loan.ratio'])),
                    Text(
                      Fmt.ratio(loan.collateralRatio),
                      style: Theme.of(context).textTheme.headline4,
                    )
                  ],
                )),
              ])
            ],
          ),
        ),
      ]),
      onTap: () => Navigator.of(context).pushNamed(
        LoanDetailPage.route,
        arguments: loan.token,
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  AccountCard(this.account);
  final KeyPairData account;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16.0,
            spreadRadius: 4.0,
            offset: Offset(2.0, 2.0),
          )
        ],
      ),
      child: ListTile(
        dense: true,
        leading: AddressIcon(account.address, svg: account.icon, size: 36),
        title: Text(account.name.toUpperCase()),
        subtitle: Text(Fmt.address(account.address)),
      ),
    );
  }
}

class AccountCardLayout extends StatelessWidget {
  AccountCardLayout(this.account, this.child);
  final KeyPairData account;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        margin: EdgeInsets.only(top: 64),
        child: child,
      ),
      AccountCard(account),
    ]);
  }
}

class CollateralIncentiveList extends StatelessWidget {
  CollateralIncentiveList(
      {this.loans,
      this.incentives,
      this.rewards,
      this.totalCDPs,
      this.tokenIcons,
      this.prices,
      this.stableCoinDecimals,
      this.incentiveTokenSymbol});

  final Map<String, LoanData> loans;
  final Map<String, double> incentives;
  final Map<String, CollateralRewardData> rewards;
  final Map<String, TotalCDPData> totalCDPs;
  final Map<String, Widget> tokenIcons;
  final Map<String, BigInt> prices;
  final int stableCoinDecimals;
  final String incentiveTokenSymbol;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final tokens = incentives.keys.toList();
    return ListView.builder(
        itemCount: tokens.length,
        itemBuilder: (_, i) {
          final token = tokens[i];
          final apy = prices[incentiveTokenSymbol] /
              Fmt.tokenInt('1', acala_price_decimals) *
              incentives[token] /
              Fmt.bigIntToDouble(totalCDPs[token].debit, stableCoinDecimals);
          final borrowed =
              Fmt.priceCeilBigInt(loans[token].debits, stableCoinDecimals);
          final reward = rewards[token];
          final rewardView =
              reward != null ? Fmt.priceFloor(reward.reward, lengthMax: 6) : '';
          return RoundedCard(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
            margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                          margin: EdgeInsets.only(right: 8),
                          child: TokenIcon(token, tokenIcons)),
                      Text(PluginFmt.tokenView(token),
                          style: TextStyle(
                            fontSize: 30,
                            letterSpacing: -0.8,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          )),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Text(
                              '${dic['loan.apy']} ($incentiveTokenSymbol)'),
                        ),
                        Text(Fmt.ratio(apy),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            )),
                      ],
                    )),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Text(
                              '${dic['loan.borrowed']} ($acala_stable_coin_view)'),
                        ),
                        Text(borrowed,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            )),
                      ],
                    ))
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 24),
                  child: reward != null && reward.reward > 0.00001
                      ? TxButton(
                          text:
                              '${dic['earn.claim']} $rewardView $incentiveTokenSymbol',
                          getTxParams: () async {
                            final pool = {
                              'LoansIncentive': {'Token': token}
                            };
                            return TxConfirmParams(
                              module: 'incentives',
                              call: 'claimRewards',
                              txTitle: dic['earn.claim'],
                              txDisplay: {
                                'pool': pool,
                                'amount': '$rewardView $incentiveTokenSymbol'
                              },
                              params: [pool],
                            );
                          },
                          onFinish: (_) => null,
                        )
                      : RoundedButton(text: dic['earn.claim']),
                )
              ],
            ),
          );
        });
  }
}
