import 'dart:async';

import 'package:charts_painter/chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonic Sound Meter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  NoiseMeterApp(),
    );
  }
}

class NoiseMeterApp extends StatefulWidget {
  @override
  _NoiseMeterAppState createState() => _NoiseMeterAppState();
}

class _NoiseMeterAppState extends State<NoiseMeterApp> {
  bool _isRecording = false;
  NoiseReading? _latestReading;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  NoiseMeter? noiseMeter;
  double higestVal=0;
  List<double> noiseList=[];
  Timer? _timer;
  // bool isInsAdLoaded = false;
  // late InterstitialAd interstitialAd;
  late BannerAd bannerAd;
  bool isAdLoaded = false;

  @override
  void initState() {
    //initInterstialAd();
    initBannerAd();
    super.initState();
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    super.dispose();
  }

  void onData(NoiseReading noiseReading) async{

    setState(() {
      _latestReading = noiseReading;
      setHigestValue(_latestReading!.meanDecibel);
    });


  }
  void startContinuousLoop() {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {

        if(noiseList.length>=100){
          noiseList.clear();
        }
       // print('Function called at: ${DateTime.now()}');
        setState(() {
          noiseList.add(_latestReading!.meanDecibel);
        });
      });
    }
  }

  void stopContinuousLoop() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }


  void onError(Object error) {
    print(error);
    stop();
  }

  /// Check if microphone permission is granted.
  Future<bool> checkPermission() async => await Permission.microphone.isGranted;

  /// Request the microphone permission.
  Future<void> requestPermission() async =>
      await Permission.microphone.request();

  /// Start noise sampling.
  Future<void> start() async {
    // Create a noise meter, if not already done.
    noiseMeter ??= NoiseMeter();

    // Check permission to use the microphone.
    //
    // Remember to update the AndroidManifest file (Android) and the
    // Info.plist and pod files (iOS).
    if (!(await checkPermission())) await requestPermission();

    // Listen to the noise stream.
    _noiseSubscription = noiseMeter?.noise.listen(onData, onError: onError);
    startContinuousLoop();
    setState(() => _isRecording = true);

    //add
    if (isAdLoaded) {
      print('This is calleddddd 2');
      initBannerAd().show();
    }
  }

  /// Stop sampling.
  void stop() {
    _noiseSubscription?.cancel();
    stopContinuousLoop();
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(

      body: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    margin: EdgeInsets.all(25),
                    child: Column(children: [
                      // Container(
                      //   child: Text(_isRecording ? "Mic: ON" : "Mic: OFF",
                      //       style: TextStyle(fontSize: 25, color: Colors.blue)),
                      //   margin: EdgeInsets.only(top: 20),
                      // ),
                      Container(
                        width: MediaQuery.sizeOf(context).width,
                        height: 60,
                        margin: EdgeInsets.only(top: 20),
                        child: isAdLoaded
                            ? SizedBox(
                          height: bannerAd.size.height.toDouble(),
                          width: bannerAd.size.width.toDouble(),
                          child: AdWidget(
                            ad: bannerAd,
                          ),
                        )
                            : SizedBox(),
                      ),
                      SfRadialGauge(
                        axes: <RadialAxis>[
                          RadialAxis(minimum: 0, maximum: 200, labelOffset: 30,
                              axisLineStyle: AxisLineStyle(
                                  thicknessUnit: GaugeSizeUnit.factor,thickness: 0.08),

                              majorTickStyle: MajorTickStyle(length: 6,thickness: 4,color: Colors.white),
                              minorTickStyle: MinorTickStyle(length: 3,thickness: 3,color: Colors.white),
                              axisLabelStyle: GaugeTextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 14 ),

                              ranges: <GaugeRange>[
                                GaugeRange(startValue: 0, endValue: 200, sizeUnit: GaugeSizeUnit.factor,startWidth: 0.12,endWidth: 0.12,
                                    gradient: SweepGradient(
                                        colors: const<Color>[Colors.green,Colors.yellow,Colors.red],
                                        stops: const<double>[0.0,0.5,1]))],

                              pointers: <GaugePointer>[NeedlePointer(value:_latestReading==null?0:_latestReading!.meanDecibel, needleLength: 0.95, enableAnimation: true,
                                  animationType: AnimationType.ease, needleStartWidth: 1.5, needleEndWidth: 6, needleColor: Colors.red,
                                  knobStyle: KnobStyle(knobRadius: 0.09))],
                              annotations: <GaugeAnnotation>[
                                GaugeAnnotation(widget: Container(child:
                                Column(
                                    children: <Widget>[
                                      Text('${_latestReading==null?0:_latestReading!.meanDecibel.toStringAsFixed(2)} db', style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold,color: Colors.black)),
                                      SizedBox(height: 20),
                                      Text('Max: ${higestVal.toStringAsFixed(0)} db', style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold)),
                                      // SizedBox(height: 10,),
                                      // Text(
                                      //   'Max: ${higestVal.toStringAsFixed(2)} dB',
                                      // ),
                                    ]
                                )), angle: 90, positionFactor: 1.4)]

                          ),
                        ],

                      ),
                      // Container(
                      //   child: Text(
                      //     'Noise: ${_latestReading?.meanDecibel.toStringAsFixed(2)} dB',
                      //   ),
                      //   margin: EdgeInsets.only(top: 20),
                      // ),
                      // Container(
                      //   child: Text(
                      //     'Max: ${higestVal.toStringAsFixed(2)} dB',
                      //   ),
                      // ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: _isRecording ? Colors.red : Colors.green,
                          padding: EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        onPressed: _isRecording ? stop : start,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10), // Add some spacing between the icon and text
                            Text(
                              _isRecording ? 'Stop' : 'Start',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    ])),
               Container(height: 260,
                 padding: EdgeInsets.only(top: 10,right: 10),
                 child: LineChart(
                   LineChartData(
                     gridData: FlGridData(show: true),
                     titlesData: FlTitlesData(
                       show: true,
                       // bottomTitles: AxisTitles(),
                       //leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,),axisNameWidget: Text('speed',style: TextStyle(fontSize: 10),)),
                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false,reservedSize: 20,),axisNameWidget: Text('Time (seconds)',style: TextStyle(fontSize: 10),)),
                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false),axisNameWidget: Text('Sound (db/s)',style: TextStyle(fontSize: 10),)),
                     ),
                     borderData: FlBorderData(show: true),
                     minX: 0,
                     maxX: 100,
                     minY: 40,
                     maxY: 160,

                     lineBarsData: [
                       LineChartBarData(
                         spots: noiseList.asMap().entries.map((entry) {
                           return FlSpot(entry.key.toDouble(), entry.value);
                         }).toList(),
                         isCurved: true,
                         dotData: FlDotData(show: false),
                         belowBarData: BarAreaData(show: false),
                         color: Colors.red,
                         barWidth: 2,
                       ),
                     ],
                   ),
                 ),)

              ])),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: _isRecording ? Colors.red : Colors.green,
      //   child: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
      //   onPressed: _isRecording ? stop : start,
      // ),
    ),
  );


  double setHigestValue(double value1){

    if(higestVal>value1){
      higestVal=higestVal;
    }
    else{
      higestVal=value1;
    }
    return higestVal;
  }

  // initInterstialAd() {
  //   print('THIS IS CALLED');
  //   InterstitialAd.load(
  //     adUnitId: AdHelper.interstitialAdUnitId,
  //     request: const AdRequest(),
  //     adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
  //       print('ADD IS LOADED');
  //       interstitialAd = ad;
  //       setState(() {
  //         isInsAdLoaded = true;
  //       });
  //       interstitialAd.fullScreenContentCallback =
  //           FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
  //             initInterstialAd();
  //             // ad.dispose();
  //             // setState(() {
  //             //   isInsAdLoaded=true;
  //             // });
  //           });
  //     }, onAdFailedToLoad: (err) {
  //       interstitialAd.dispose();
  //       print('ADD ERROR ${err}');
  //     }),
  //   );
  // }

  initBannerAd() {
    bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: AdHelper.bannerAdUnitId,
        listener: BannerAdListener(onAdLoaded: (ad) {
          setState(() {
            isAdLoaded = true;
          });
        }, onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print(error);
          initBannerAd();
        }),
        request: const AdRequest());
    bannerAd.load();
  }
}
