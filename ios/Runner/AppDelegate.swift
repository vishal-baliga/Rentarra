import UIKit
import Flutter
import GoogleMaps
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Firebase initialization
    FirebaseApp.configure()

    // ✅ Google Maps initialization (replace with your real key)
    GMSServices.provideAPIKey("YAIzaSyAi2FoBGhuNMEd1pXwNynU8dJm3jdTlXB4")

    // ✅ Register plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
