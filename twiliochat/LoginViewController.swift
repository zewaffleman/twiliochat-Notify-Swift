import UIKit

class LoginViewController: UIViewController {
    
    //Adding Push Notifications to progChat Quickstart
    
    var serverURL = "https://notifyav-4948-dev.twil.io"
    var path = "/TwilioNotify_RegBinding"
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var messageLabel: UILabel!
    
    // MARK: - Injectable Properties
    
    var alertDialogControllerClass = AlertDialogController.self
    var MessagingClientClass = MessagingManager.self
    
    // MARK: - Initialization
    
    var textFieldFormHandler: TextFieldFormHandler!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeTextFields()
    }
    
    func initializeTextFields() {
        let textFields: [UITextField] = [usernameTextField]
        textFieldFormHandler = TextFieldFormHandler(withTextFields: textFields, topContainer: view)
        textFieldFormHandler.delegate = self
    }
    
    func resetFirstResponderOnSignUpModeChange() {
        self.view.layoutSubviews()
        
        if let index = self.textFieldFormHandler.firstResponderIndex {
            if (index > 1) {
                textFieldFormHandler.setTextFieldAtIndexAsFirstResponder(index: 1)
            }
            else {
                textFieldFormHandler.resetScroll()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textFieldFormHandler.cleanUp()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTouched(_ sender: UIButton) {
        //log them in regardless of if it is running in the simulator
        loginUser()
    }
    
    func displayError(_ errorMessage:String) {
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Login
    
    func loginUser() {
        if (validUserData()) {
            view.isUserInteractionEnabled = false
            activityIndicator.startAnimating()
            
            let MessagingManager = MessagingClientClass.sharedManager()
            if let username = usernameTextField.text {
                MessagingManager.loginWithUsername(username: username, completion: handleResponse)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let deviceToken : String! = appDelegate.devToken
                let identity : String! = self.usernameTextField.text
               
                registerDevice(identity, deviceToken: deviceToken)
                resignFirstResponder()
            }
        }
    }
    
    func validUserData() -> Bool {
        if let usernameEmpty = usernameTextField.text?.isEmpty, !usernameEmpty {
            return true
        }
        showError(message: "All fields are required")
        return false
    }
    
    func showError(message:String) {
        alertDialogControllerClass.showAlertWithMessage(message: message, title: nil, presenter: self)
    }
    
    func handleResponse(succeeded: Bool, error: NSError?) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            if let error = error, !succeeded {
                print("responce handler")
                self.showError(message: error.localizedDescription)
            }
            self.view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - Style
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            return .all
        }
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    // MARK: - Register
    
    func registerDevice(_ identity: String, deviceToken: String) {

        // Create a POST request to the /register endpoint with device variables to register for Twilio Notifications
        let session = URLSession.shared

        let url = URL(string: serverURL + path)
        var request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.httpMethod = "POST"

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = ["identity": identity,
                      "BindingType" : "apn",
                      "Address" : deviceToken]

        let jsonData = try! JSONSerialization.data(withJSONObject: params, options: [])
        request.httpBody = jsonData

        let requestBody = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
        print("Request Body: \(requestBody ?? "")")

        let task = session.dataTask(with: request, completionHandler: {
            (responseData, response, error) in

          if let responseData = responseData {
            let responseString = String(data: responseData, encoding: String.Encoding.utf8)

            print("Response Body: \(responseString ?? "")")
            do {
                let responseObject = try JSONSerialization.jsonObject(with: responseData, options: [])
                if let responseDictionary = responseObject as? [String: Any] {
                    if let message = responseDictionary["message"] as? String {
                        //print("Message: \(message)")

                        DispatchQueue.main.async() {
                            //print("Binding Created")
                            /*
                            self.messageLabel.text = message
                            self.messageLabel.isHidden = false
                             */
                        }
                    }
                }
                print("JSON: \(responseObject)")
            } catch let error {
                print("Error: \(error)")
            }
            }
        })

        task.resume()
      }
}


// MARK: - TextFieldFormHandlerDelegate
extension LoginViewController : TextFieldFormHandlerDelegate {
    func textFieldFormHandlerDoneEnteringData(handler: TextFieldFormHandler) {
        loginUser()
    }
    

}
