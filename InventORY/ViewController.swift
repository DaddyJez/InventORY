import UIKit
import SwiftUI
import LazyViewSwiftUI

class ViewController: UIViewController {
    let databaseManager = SupabaseManager()
    var userData: [String: String] = [:]
    
    @IBOutlet weak var loginEl: UITextField!
    @IBOutlet weak var passwEl: UITextField!
    
    @objc func dismissKeyboard() {
            view.endEditing(true)
        }

    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var labelGreeting: UILabel!
    
    @IBOutlet weak var registerOrLogin: UISegmentedControl!
    
    @IBAction func goButtonPressed(_ sender: Any) {
        Task { @MainActor in
            let user = UserControls(login: loginEl.text ?? "", password: passwEl.text ?? "")
            dismissKeyboard()
            goButton.isHidden = true
            
            if registerOrLogin.selectedSegmentIndex == 0 {
                if await (user.tryToLog()){
                    ifRegistered()
                } else {
                    labelGreeting.text = "Wrong login or password"
                }
            } else if await (user.register()) {
                labelGreeting.text = "Registered, \(loginEl.text ?? "User")!"
            } else {
                labelGreeting.text = "Try another login"
            }
            goButton.isHidden = false
        }
    }
    
    func autoLogin() async {
        let user = UserControls(login: loginEl.text ?? "", password: passwEl.text ?? "")
        if await (user.tryToLog()){
            ifRegistered()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            self.userData = self.databaseManager.DefaultsOperator.loadUserData()
            
            if self.userData.isEmpty == false {
                goButton.isHidden = true
                loginEl.text = self.userData["login"]
                passwEl.text = self.userData["password"]
                
                await autoLogin()
                goButton.isHidden = false
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        }
    
    @IBAction func ifRegistered() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController2")
        
        self.navigationController?.setViewControllers([vc], animated: true)
    }
}

