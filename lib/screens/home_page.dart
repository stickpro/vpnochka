import 'dart:async';
import 'dart:convert';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wireguard_flutter/repository/models.dart';
import 'package:wireguard_flutter/screens/server_list_page.dart';
import 'package:wireguard_flutter/utils/public_ip.dart';

import 'shared_widgets/server_list_widget.dart';

const initName = 'VPNOCHKA';
const initAddress = "10.0.0.12/32";
const initPort = "51830";
const initDnsServer = "1.1.1.1";
const initPrivateKey = "COJ+bbLGAvUTitiP2dzHGAPH2IuZCjy4L/7wGyW0aGg=";
const initAllowedIp = "0.0.0.0/0";
const initPublicKey = "0lKqlNXRmb9WWc8DA22QdCfloDWXm8U4YPw3Hqz82zE=";
const initEndpoint = "92.222.195.251:51830";

const kBgColor = Color(0xffff5758);

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = const MethodChannel('stick.pro/wireguard-flutter');
  String _name = initName;
  String _address = initAddress;
  String _listenPort = initPort;
  String _dnsServer = initDnsServer;
  String _privateKey = initPrivateKey;
  String _peerAllowedIp = initAllowedIp;
  String _peerPublicKey = initPublicKey;
  String _peerEndpoint = initEndpoint;
  bool _connected = true;
  bool _scrolledToTop = true;
  bool _gettingStats = true;
  Stats? _stats;
  Timer? _gettingStatsTimer;

  int sliderIndex = -1;

  Duration _duration = const Duration();
  Timer? _timer;

  startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      const addSeconds = 1;
      setState(() {
        final seconds = _duration.inSeconds + addSeconds;
        _duration = Duration(seconds: seconds);
      });
    });
  }

  stopTimer() {
    setState(() {
      _timer?.cancel();
      _duration = const Duration();
    });
  }

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStateChange':
          try {
            final stats = StateChangeData.fromJson(jsonDecode(call.arguments));
            if (stats.tunnelState) {
              setState(() => _connected = true);
              _startGettingStats(context);
            } else {
              setState(() => _connected = false);
              _stopGettingStats();
            }
          } catch (e) {
            print(e);
          }

          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: kBgColor,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: kBgColor,
            statusBarBrightness: Brightness.dark, // For iOS: (dark icons)
            statusBarIconBrightness:
                Brightness.light, // For Android: (dark icons)
          ),
          centerTitle: true,
          title: Text(
            'VPNOCHKA',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          leading: Image.asset(
            'assets/logo.png',
            width: 35,
            height: 35,
          ),
        ),
        body: StreamBuilder(
          builder: (context, snapshot) {
            return Stack(
              children: [
                Positioned(
                    top: 50,
                    child: Opacity(
                      opacity: .1,
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/background_dark.png'
                            : 'assets/background.png',
                        fit: BoxFit.fill,
                        height: MediaQuery.of(context).size.height / 1.5,
                      ),
                    )),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        SizedBox(height: 25),
                        Center(
                            child: Text(
                          'Connected status',
                          style: Theme.of(context).textTheme.bodyLarge,
                        )),
                        SizedBox(height: 8),
                        FutureBuilder(
                            future: getPublicIP(),
                            builder:
                                (context, AsyncSnapshot<dynamic> snapshot) {
                              final ip = snapshot.data;
                              return Center(
                                  child: Text(
                                ip ?? "ip not detected",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                        color: kBgColor,
                                        fontWeight: FontWeight.w600),
                              ));
                            }),
                        Spacer(),
                        Center(
                          child: InkWell(
                            onTap: () {
                              _connected ? startTimer() : stopTimer();
                              _setTunnelState(context);
                            },
                            borderRadius: BorderRadius.circular(90),
                            child: AvatarGlow(
                              glowColor: kBgColor,
                              endRadius: 100.0,
                              duration: Duration(microseconds: 100),
                              repeat: true,
                              showTwoGlows: true,
                              repeatPauseDuration: Duration(milliseconds: 100),
                              shape: BoxShape.circle,
                              child: Material(
                                elevation: 1.0,
                                shape: CircleBorder(),
                                color: kBgColor,
                                child: SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.power_settings_new,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        _connected ? "Connect!" : 'Disconnect',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(color: Colors.white),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: _connected ? 90 : size.height * 0.14,
                              height: size.height * 0.030,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            _countDownWidget(size),
                          ],
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        ServerItemWidget(
                          flagAsset: 'assets/logo.png',
                          label: 'No sever selected',
                          icon: Icons.arrow_forward_ios,
                          onTap: () async {
                            final res = await Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) {
                              return ServerListPage();
                            }));

                            if (res != null) {
                              print("connect");
                            }
                          },
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal:
                                    MediaQuery.of(context).size.width / 4.5),
                            backgroundColor: kBgColor,
                          ),
                          onPressed: () {},
                          icon: Icon(
                            Icons.star,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Get Premium',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 35),
                      ],
                    )),
              ],
            );
          },
        ));
  }

  Widget _countDownWidget(Size size) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    final hours = twoDigits(_duration.inHours.remainder(60));

    return Text(
      '$hours : $minutes : $seconds',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Future _setTunnelState(BuildContext context) async {
    try {
      final result = await platform.invokeMethod(
        'setState',
        jsonEncode(SetStateParams(
          state: _connected,
          tunnel: Tunnel(
            name: _name,
            address: _address,
            dnsServer: _dnsServer,
            listenPort: _listenPort,
            peerAllowedIp: _peerAllowedIp,
            peerEndpoint: _peerEndpoint,
            peerPublicKey: _peerPublicKey,
            privateKey: _privateKey,
          ),
        ).toJson()),
      );
      if (result == true) {
        setState(() => _connected = !_connected);
      }
    } on PlatformException catch (e) {
      _showError(context, e.toString());
    }
  }

  _startGettingStats(BuildContext context) {
    _gettingStatsTimer?.cancel();
    _gettingStatsTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!_gettingStats) {
        timer.cancel();
      }
      try {
        final result = await platform.invokeMethod('getStats', _name);
        final stats = Stats.fromJson(jsonDecode(result));
        setState(() => _stats = stats);
      } catch (e) {
        // can't get scaffold context from initState. todo: fix this
        //_showError(context, e.toString());
      }
    });
  }

  _stopGettingStats() {
    setState(() => _gettingStats = false);
  }

  _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        error,
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: Colors.white),
      ),
      backgroundColor: Colors.red[400],
    ));
  }
}
