import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Trigger SDK Example'),
        ),
        body: const SDKTriggerButton(), // Display the SDK trigger button and the result
      ),
    );
  }
}

class SDKTriggerButton extends StatefulWidget {
  const SDKTriggerButton({super.key});


  @override
  State<SDKTriggerButton> createState() => _SDKTriggerButtonState();
}

class _SDKTriggerButtonState extends State<SDKTriggerButton> {
  static const platformChannel = MethodChannel('com.fundall.gettallysdkui');
  static const EventChannel _eventChannel = EventChannel('com.netplus.qrengine.tallysdk/tokenizedCardsData');


  List<SavedTallyData> savedData = [];

  bool useMethod = true;

  @override
  void initState() {

    if (useMethod){
      _fetchQRCodesFromTally();
    }else{
      _tokenizedCardsDataStream.listen((result) {

        if (result != null) {
          _mapData(result);
        }
      });
    }
    super.initState();
  }

  /// Stream to listen for data returned from the native side
  static Stream<dynamic> get _tokenizedCardsDataStream {
    return _eventChannel.receiveBroadcastStream();
  }

  void _fetchQRCodesFromTally() async {
    try {
      final dynamic result = await platformChannel.invokeMethod('fetchMethod');
      if (result != null) {
        _mapData(result);
      }

    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error: ${e.message}');
      }
    }
  }

  void _mapData(dynamic result){
    final data = Map<String, dynamic>.from (result as Map);
    List<Map<String, String>> values = [];
    final dataValue = data["data"];
    for (var dt in dataValue){
      values.add(Map<String, String>.from (dt as Map));
    }
    final dataMapped = {"data" : values};

    final fetchedData = SavedTally.fromJson(dataMapped);
    setState(() {
      savedData = fetchedData.data;
    });
  }

  Future<void> _triggerSdkFunction() async {
    try {
      // Invoke the native method to start the SDK activity
      final String result = await platformChannel.invokeMethod('startTallyActivity', {
        // Pass any required arguments to the native method
        "email": "email@example.com",
        "fullName": "John Doe",
        "bankName": "GTBank",
        "phoneNumber": "000000000",
        "userId": "00",
        "activationKey": "activationKey",
        "apiKey": "apiKey"
      });
      if (kDebugMode) {
        print(result);
      } // Print success result from native code
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to invoke the method: '${e.message}'.");
      }
    }
  }

  @override
  void dispose() {// Close the stream when disposing.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            _triggerSdkFunction(); // Call this function when the button is pressed
          },
          child: const Text('Trigger SDK'),
        ),

        Expanded(
          child: Visibility(
            child: cardDetails(savedData)
          ),
        ),

      ],
    );
  }
  
  Widget cardDetails(List<SavedTallyData> savedData){
    return ListView.builder(
      itemCount: savedData.length,
      itemBuilder: (context, position) {
        final data = savedData[position];
        return  Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.memory(base64Decode(data.image), height: 120, width: 120,),
                const SizedBox(width: 16,),
                Text(
                  data.issuingBank,
                  style: const TextStyle(fontSize: 22.0),
                ),
              ],
            ),
          ),
        );
      },
    );

  }
}






class SavedTally {
  final List<SavedTallyData> data;

  SavedTally({
    required this.data,
  });

  factory SavedTally.fromJson(Map<String, dynamic> json) => SavedTally(
    data: List<SavedTallyData>.from(json["data"].map((x) => SavedTallyData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class SavedTallyData {
  final String qrcodeId;
  final String image;
  final String cardScheme;
  final String issuingBank;
  final String date;

  SavedTallyData({
    required this.qrcodeId,
    required this.image,
    required this.cardScheme,
    required this.issuingBank,
    required this.date,
  });

  factory SavedTallyData.fromJson(Map<String, dynamic> json) => SavedTallyData(
    qrcodeId: json["qrcodeId"],
    image: json["image"],
    cardScheme: json["cardScheme"],
    issuingBank: json["issuingBank"],
    date: json["date"],
  );

  Map<String, dynamic> toJson() => {
    "qrcodeId": qrcodeId,
    "image": image,
    "cardScheme": cardScheme,
    "issuingBank": issuingBank,
    "date": date,
  };
}




