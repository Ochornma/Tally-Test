import Flutter
import UIKit
import TallyiOS


@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {

    // Define the channel identifier
    private let CHANNEL = "com.fundall.gettallysdkui"
    // Define the methods identifier
    private let deleteMethod = "deleteMethod"
    private let fetchMethod = "fetchMethod"
    private let startTallyActivity = "startTallyActivity"
    
    // Declare our eventSink, it will be initialized later
    private var eventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set up the MethodChannel with the same name as defined in Dart
        if let flutterViewController = window?.rootViewController as? FlutterViewController {
            let methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: flutterViewController.binaryMessenger)
            methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: FlutterResult) in
                if call.method == self?.fetchMethod {
                    // Perform platform-specific operations and obtain the result
                    let data = self?.getDataFromTally()

                    // Send the result back to Flutter
                    result(data)
                } else if call.method == self?.deleteMethod {
                    self?.deleteDataFromTally(result: result)
                } else if call.method == self?.startTallyActivity {
                    self?.startSDK(call: call, result: result)
                }else{
                    result(FlutterMethodNotImplemented)
                }
            }

            ///If you prefer event listener you can also retrieve QR codes using event listeners
            //// Uncomment the code below to use eventChannel
         /*   let eventChannel = FlutterEventChannel(name: "com.netplus.qrengine.tallysdk/tokenizedCardsData", binaryMessenger: flutterViewController.binaryMessenger)
                     eventChannel.setStreamHandler(object : StreamHandler {
                      override func onListen(arguments: Any?, eventSink: EventSink) {
                       let data = self.getDataFromTally()
                        eventSink(data)
                     }

                    override func onCancel(arguments: Any?) {
                       eventSink = nil
                     }
                   })

            */
            let eventChannel = FlutterEventChannel(name: "com.netplus.qrengine.tallysdk/tokenizedCardsData", binaryMessenger: flutterViewController.binaryMessenger)
            eventChannel.setStreamHandler(self)
        }
        
        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

   /* func getDataFromTally() -> EncryptedQrModelData? {
        return TallDataUtil.shared.retrieveData()
    }*/
    
    private  func getDataFromTally() -> [String: Any]? {
        
        
        let savedData = TallDataUtil.shared.retrieveData()
      guard let savedData else {
        return nil
      }
       let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(savedData)
     let formattedResponse = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
      return formattedResponse
      }catch {
        return nil
      }
    }

    func deleteDataFromTally(result:  FlutterResult) {
        do {
            try TallDataUtil.shared.deleteAllData()
            result("Success")
        }catch let error {
            result(FlutterError(code: "Delete Failed", message: error.localizedDescription, details: nil))
        }
    }
    func startSDK(call: FlutterMethodCall, result:  FlutterResult) {
        if let data = call.arguments as? [String: Any]{
            guard let email = data["email"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enter email", details: nil))
                return
            }
            guard let bankName = data["bankName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enter bankName", details: nil))
                return
            }
            guard let fullName = data["fullName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enter fullName", details: nil))
                return
            }
            guard let phoneNumber = data["phoneNumber"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enter phoneNumber", details: nil))
                return
            }
            guard let userId = data["userId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enter userId", details: nil))
                return
            }
            guard let apiKey = data["apiKey"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enter apiKey", details: nil))
                return
            }
            guard let activationKey = data["activationKey"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Enter activationKey", details: nil))
                return
            }
            let param = TallyParam(userId: userId, userFullName: fullName, userEmail: email, userPhone: phoneNumber, bankName: bankName, staging: true, apiKey: apiKey, activationKey: activationKey)
            guard let controller = UIApplication.shared.windows.first?.rootViewController else{
                return
            }
            param.openTallySdk(controller: controller)
        }else{
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Can't open SDK", details: nil))
        }
    }
    
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        print("onListen......")
        self.eventSink = eventSink
        let dataFetched = getDataFromTally()
        eventSink(dataFetched)
        
    
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    

}
