import UIKit
import Flutter
import Stripe

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "stripe_plugin", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler {(call: FlutterMethodCall, result: FlutterResult) -> Void in
      if (call.method == "setupStripe") {
          if let args = call.arguments as? Dictionary<String, Any>,
            let publishableKey = args["publishableKey"] as? String {
            STPAPIClient.shared.publishableKey = publishableKey
          } else {
            result(FlutterError.init(code: "bad args", message: nil, details: nil))
          }
          print("setup done")
        } else if (call.method == "startPaymentFlow") {
          print("startPaymentFlow")
          if let args = call.arguments as? Dictionary<String, Any>,
             let ephemeralKey = args["ephemeralKey"] as? String,
             let paymentIntentSecret = args["paymentIntentSecret"] as? String,
             let customerId = args["customerId"] as? String {

            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Test"
    //        configuration.applePay = .init(merchantId: "merchant.com.your_app_name", merchantCountryCode: "GB")
            configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
            let paymentSheet: PaymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentSecret, configuration: configuration)
            paymentSheet.present(from: controller) { paymentResult in
                switch paymentResult {
                case .completed:
                  channel.invokeMethod("paymentResult", arguments: "completed")
                  print("Payment succeeded!")
                case .canceled:
                  channel.invokeMethod("paymentResult", arguments: "canceled")
                  print("Canceled!")
                case .failed(let error, _):
                  channel.invokeMethod("paymentResult", arguments: "failed")
                  print("Payment failed: \n\(error.localizedDescription)")
                }
              }

          } else {
            result(FlutterError.init(code: "bad args", message: nil, details: nil))
          }
        }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
