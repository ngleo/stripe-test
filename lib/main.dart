import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:treeapp_stripe_plugin/treeapp_stripe_plugin.dart';

void main() {
  runApp(MyApp());
}

enum PaymentResult { completed, failed, canceled }

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // setupLocator();

    // TreeappStripePlugin.
    init(
        "pk_test_51Hs8nUBYwOfZ2CjY6EkcPQnC13Rl1mHKBro6gew1ooHtxAXMdMTUCj62ZDi0swL9XTLVcBkRPtvs46Hs5BXOmLwT00T6ngnpOc");
  }

  static const MethodChannel _channel = const MethodChannel('treeapp_stripe_plugin');

  static Future<void> init(String publishableKey,
      [String applePayMerchantIdentifier]) async {
    final Map<String, String> args = {"publishableKey": publishableKey};
    if (applePayMerchantIdentifier != null) {
      args["applePayMerchantIdentifier"] = applePayMerchantIdentifier;
    }
    await _channel.invokeMethod("setupStripe", args);
  }

  static Future<void> startPaymentFlow(
      {@required String ephemeralKey,
      @required String paymentIntentSecret,
      @required String customerId,
      @required Function() onComplete,
      @required Function() onFail,
      @required Function() onCancel}) async {
    final Map<String, String> args = {
      "ephemeralKey": ephemeralKey,
      "paymentIntentSecret": paymentIntentSecret,
      "customerId": customerId
    };

    _setupChannelMethodHandler(onComplete, onFail, onCancel);

    await _channel.invokeMethod("startPaymentFlow", args);
  }

  static void _setupChannelMethodHandler(
      Function() onComplete, Function() onFail, Function() onCancel) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "paymentResult":
          PaymentResult res = PaymentResult.values.firstWhere(
              (e) => e.toString().split(".")[1] == call.arguments.toString(),
              orElse: () => null);
          switch (res) {
            case PaymentResult.completed:
              onComplete();
              break;
            case PaymentResult.failed:
              onFail();
              break;
            case PaymentResult.canceled:
              onCancel();
              break;
          }
          break;
        default:
          throw MissingPluginException("notImplemented");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // RaisedButton(
              //   onPressed: () => getPaymentIntent(),
              //   child: Text("Get payment intent"),
              // ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(onPressed: () async {
          Dio dio = Dio()..options.baseUrl = "http://192.168.0.104:8080";
          Map data = {
            "userId": "cus_Ic6qhcpZkOsOvc",
            "amount": 1 * 100,
          };
          Response res = await dio.post("/stripe/createPayment", data: data);
          print(res.data);
          // TreeappStripePlugin.
          startPaymentFlow(
            ephemeralKey: res.data["ephemeralKey"],
            paymentIntentSecret: res.data["paymentIntentSecret"],
            customerId: res.data["customerId"],
            onComplete: () => print("completed"),
            onFail: () => print("failed"),
            onCancel: () => print("cancelled"),
          );
        }),
      ),
    );
  }

  SnackBar snackbar(String s) {
    return SnackBar(content: Text(s));
  }
}
