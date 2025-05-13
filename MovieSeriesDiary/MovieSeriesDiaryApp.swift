import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct MovieSeriesDiaryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var vM: BindingPageViewModel
    @StateObject var loginVM: LoginPageViewModel
    
    init() {
        let bindingVM = BindingPageViewModel()
        _vM = StateObject(wrappedValue: bindingVM)
        _loginVM = StateObject(wrappedValue: LoginPageViewModel(vM: bindingVM))
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                if Auth.auth().currentUser != nil && vM.user == nil {
                    ProgressView()
                        .onAppear {
                            if let email = Auth.auth().currentUser?.email {
                                loginVM.fetchUserData(email: email) { user in
                                    vM.user = user
                                }
                            }
                        }
                } else {
                    LoginPage(vM: vM, loginVM: loginVM)
                }
            }
        }
    }
}
