import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/pages/swap/bootstrapList.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapForm.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/pageTitleTaps.dart';

class SwapPage extends StatefulWidget {
  SwapPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/dex';

  @override
  _SwapPageState createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.plugin.service.earn.getDexPools();
    });
  }

  @override
  Widget build(_) {
    final isKar = widget.plugin.basic.name == plugin_name_karura;
    // final bool enabled = !isKar || ModalRoute.of(context).settings.arguments;
    final bool enabled = true;
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');

        final dexPools = widget.plugin.store.earn.dexPools;

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 240,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).canvasColor
                  ],
                  stops: [0.4, 0.9],
                )),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              color: Theme.of(context).cardColor),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: PageTitleTabs(
                            names: [dic['dex.title'], dic['boot.title']],
                            activeTab: _tab,
                            onTab: (i) {
                              if (i != _tab) {
                                setState(() {
                                  _tab = i;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
                          icon: Icon(Icons.history,
                              color: Theme.of(context).cardColor),
                          onPressed: enabled
                              ? () => Navigator.of(context)
                                  .pushNamed(SwapHistoryPage.route)
                              : null,
                        ),
                      ],
                    ),
                    Expanded(
                      child: dexPools.length == 0
                          ? Center(
                              child: CupertinoActivityIndicator(),
                            )
                          : _tab == 0
                              ? SwapForm(widget.plugin, widget.keyring)
                              : BootstrapList(widget.plugin, widget.keyring),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
