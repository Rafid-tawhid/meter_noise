import 'dart:async';

import 'package:charts_painter/chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:meter_noise/xmpl.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    super.dispose();
  }

  void onData(NoiseReading noiseReading) {
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
        print('Function called at: ${DateTime.now()}');
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
  }

  /// Stop sampling.
  void stop() {
    _noiseSubscription?.cancel();
    stopContinuousLoop();
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(

      body: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    margin: EdgeInsets.all(25),
                    child: Column(children: [
                      Container(
                        child: Text(_isRecording ? "Mic: ON" : "Mic: OFF",
                            style: TextStyle(fontSize: 25, color: Colors.blue)),
                        margin: EdgeInsets.only(top: 20),
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
                                      Text('${higestVal.toStringAsFixed(0)} db', style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold))]
                                )), angle: 90, positionFactor: 1.4)]

                          ),
                        ],

                      ),
                      Container(
                        child: Text(
                          'Noise: ${_latestReading?.meanDecibel.toStringAsFixed(2)} dB',
                        ),
                        margin: EdgeInsets.only(top: 20),
                      ),
                      Container(
                        child: Text(
                          'Max: ${higestVal.toStringAsFixed(2)} dB',
                        ),
                      )
                    ])),
               if(noiseList.isNotEmpty) Container(height: 300,
                 padding: EdgeInsets.only(top: 10,right: 10),
                 color: Colors.white,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isRecording ? Colors.red : Colors.green,
        child: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
        onPressed: _isRecording ? stop : start,
      ),
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
}
