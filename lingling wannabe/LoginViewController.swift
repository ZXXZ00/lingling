//
//  LogintViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 7/4/21.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    var size: CGSize
    var floatViewDelegate: FloatView?
    
    let label = UILabel()
    let username = UITextField()
    var usernameY = NSLayoutConstraint()
    let email = UITextField()
    let password = UITextField()
    let toggle = UIButton()
    let button = UIButton()
    let guest = UIButton()
    let alter = UIButton()
    let alterLabel = UILabel()
    let loading = UIActivityIndicatorView(style: .large)
    
    let register = URL(string: "https://linglingwannabe.com/user/register")!
    let signin = URL(string: "https://linglingwannabe.com/user/login")!
    var isSending = false
    
    var didLogin: ((_: String) -> Void)?
    var didRegister: ((_: String) -> Void)?
    var didContinueAsGuest: (() -> Void)?
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(_ size: CGSize, isFullScreen: Bool=false, didRegister: ((_: String) -> Void)? = nil, didLogin: ((_: String) -> Void)? = nil, didContinueAsGuest: (() -> Void)?) {
        self.size = size
        floatViewDelegate = FloatView(size)
        self.didLogin = didLogin
        self.didRegister = didRegister
        self.didContinueAsGuest = didContinueAsGuest
        super.init(nibName: nil, bundle: nil)
        if isFullScreen {
            modalPresentationStyle = .fullScreen
        } else {
            modalPresentationStyle = .custom
            transitioningDelegate = floatViewDelegate
        }
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
    
        label.textColor = .red
        label.adjustsFontSizeToFitWidth = true
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -250).isActive = true
        label.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5).isActive = true
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        username.textColor = .black
        username.backgroundColor = .white
        username.textContentType = .username
        username.layer.cornerRadius = 10
        username.layer.borderWidth = 1
        username.layer.borderColor = UIColor.black.cgColor
        let usericon = UIImageView(image: UIImage(named: "user.pdf"))
        username.leftViewMode = .always
        username.leftView = usericon
        username.autocorrectionType = .no
        username.autocapitalizationType = .none
        username.spellCheckingType = .no
        username.smartQuotesType = .no
        username.smartDashesType = .no
        username.smartInsertDeleteType = .no
        username.attributedPlaceholder = NSAttributedString(string: "username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        view.addSubview(username)
        username.translatesAutoresizingMaskIntoConstraints = false
        username.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        usernameY = username.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -200)
        usernameY.isActive = true
        username.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        username.heightAnchor.constraint(equalToConstant: 40).isActive = true
        username.delegate = self
        username.returnKeyType = .next
        
        email.textColor = .black
        email.backgroundColor = .white
        email.keyboardType = .emailAddress
        email.textContentType = .emailAddress
        email.layer.cornerRadius = 10
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.black.cgColor
        let emailicon = UIImageView(image: UIImage(named: "email.pdf"))
        email.leftViewMode = .always
        email.leftView = emailicon
        email.autocorrectionType = .no
        email.autocapitalizationType = .none
        email.spellCheckingType = .no
        email.smartQuotesType = .no
        email.smartDashesType = .no
        email.smartInsertDeleteType = .no
        email.attributedPlaceholder = NSAttributedString(string: "email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        view.addSubview(email)
        email.translatesAutoresizingMaskIntoConstraints = false
        email.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        email.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -150).isActive = true
        email.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        email.heightAnchor.constraint(equalToConstant: 40).isActive = true
        email.delegate = self
        email.returnKeyType = .next
        
        password.textColor = .black
        password.backgroundColor = .white
        password.keyboardType = .asciiCapable
        password.textContentType = .newPassword
        password.layer.cornerRadius = 10
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.black.cgColor
        password.isSecureTextEntry = true
        password.clearsOnInsertion = false
        password.clearsOnBeginEditing = false
        password.leftViewMode = .always
        password.leftView = UIImageView(image: UIImage(named: "key.pdf"))
        password.rightViewMode = .always
        let passwordToggle = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        passwordToggle.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        let eye = UIImage(systemName: "eye")?.withTintColor(.black, renderingMode: .alwaysOriginal)
        passwordToggle.setImage(eye, for: .selected)
        let eyeSlash = UIImage(systemName: "eye.slash")?.withTintColor(.black, renderingMode: .alwaysOriginal)
        passwordToggle.setImage(eyeSlash, for: .normal)
        passwordToggle.addTarget(self, action: #selector(showHidePassword(sender:)), for: .touchUpInside)
        password.rightView = passwordToggle
        password.attributedPlaceholder = NSAttributedString(string: "minimum length 8", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        view.addSubview(password)
        password.translatesAutoresizingMaskIntoConstraints = false
        password.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        password.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -100).isActive = true
        password.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6).isActive = true
        password.heightAnchor.constraint(equalToConstant: 40).isActive = true
        password.delegate = self
        
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 70).isActive = true
        button.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.22).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        guest.setAttributedTitle(underscoreText(text: "Continue as Guest", font: UIFont.systemFont(ofSize: 12)), for: .normal)
        guest.setTitleColor(.black, for: .normal)
        guest.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        guest.addTarget(self, action: #selector(guestWarning), for: .touchUpInside)
        view.addSubview(guest)
        guest.translatesAutoresizingMaskIntoConstraints = false
        guest.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        guest.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30).isActive = true
        guest.widthAnchor.constraint(equalToConstant: 120).isActive = true
        guest.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        alterLabel.text = "Already a lingling wannabe?"
        alterLabel.textColor = .black
        alterLabel.font = UIFont.systemFont(ofSize: 14)
        alterLabel.textAlignment = .center
        view.addSubview(alterLabel)
        alterLabel.translatesAutoresizingMaskIntoConstraints = false
        alterLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        alterLabel.centerYAnchor.constraint(equalTo: button.safeAreaLayoutGuide.bottomAnchor, constant: 50).isActive = true
        alterLabel.widthAnchor.constraint(equalToConstant: 250).isActive = true
        alterLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        alter.setAttributedTitle(underscoreText(text: "Login"), for: .normal)
        alter.setTitleColor(.black, for: .normal)
        alter.addTarget(self, action: #selector(changeMethod), for: .touchUpInside)
        view.addSubview(alter)
        alter.translatesAutoresizingMaskIntoConstraints = false
        alter.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        alter.centerYAnchor.constraint(equalTo: button.safeAreaLayoutGuide.bottomAnchor, constant: 80).isActive = true
        alter.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.20).isActive = true
        alter.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        loading.color = .darkGray
        loading.center = view.center
        view.addSubview(loading)
    }
    
    // 17 is the default font size for system font
    private func underscoreText(text: String, font: UIFont=UIFont.systemFont(ofSize: 17)) -> NSAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return NSAttributedString(string: text, attributes: attrs)
    }
    
    @objc func showHidePassword(sender: UIButton) {
        sender.isSelected.toggle()
        password.isSecureTextEntry.toggle()
        if let text = password.text, password.isSecureTextEntry {
            password.text?.removeAll()
            password.insertText(text)
        }
    }
    
    @objc func guestWarning() {
        let alert = UIAlertController(title: "Continue as Guest", message: "Your progress will be temporary as a guest and you may lose it", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Back", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Continue", style: .destructive, handler: asGuest))
        present(alert, animated: true)
    }
    
    @objc func asGuest(_: UIAlertAction) {
        view.removeFromSuperview()
        removeFromParent()
        if let f = didContinueAsGuest {
            f()
        }
    }
    
    @objc func changeMethod() {
        label.text = nil
        if button.currentTitle == "Login" {
            // change to sign up
            button.setTitle("Sign Up", for: .normal)
            alter.setAttributedTitle(underscoreText(text: "Login"), for: .normal)
            alterLabel.text = "Already a lingling wannabe?"
            usernameY.constant = -200
            email.alpha = 1
        } else {
            // change to login
            button.setTitle("Login", for: .normal)
            alter.setAttributedTitle(underscoreText(text: "Sign Up"), for: .normal)
            alterLabel.text = nil
            usernameY.constant = -150
            email.alpha = 0
        }
    }
    
    @objc func buttonPressed() {
        if isSending { return }
        if button.currentTitle == "Login" {
            login()
        } else {
            signup()
        }
    }
    
    private func updateLabelAndFinishLoading(text: String) {
        DispatchQueue.main.async {
            self.label.text = text
            self.loading.stopAnimating()
        }
    }
    
    private func succeed(user: String, token: Data, didSucceeded: ((_: String) -> Void)?) {
        do {
            let tokens = try JSONDecoder().decode(Tokens.self, from: token)
            CredentialManager.shared.saveToKeyChain(token: tokens)
            DispatchQueue.main.async {
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
            if let f = didSucceeded {
                f(user)
            }
        } catch {
            // most likely caused by server returning data not as Tokens format
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.label.text = "Encountered Error"
                self.loading.stopAnimating()
            }
        }
    }
    
    func login() {
        guard let user = username.text, let pass = password.text else {
            return
        }
        if pass.count < 8 {
            label.text = "Wrong Password"
            return
        }
        loading.startAnimating()
        isSending = true
        postJSON(url: signin, json: ["username": user, "password": pass], success: { data, res in
            print(res.statusCode)
            if res.statusCode != 200 {
                self.updateLabelAndFinishLoading(text: "Wrong Password")
            } else {
                self.succeed(user: user, token: data, didSucceeded: self.didLogin)
            }
            self.isSending = false
        }, failure: { err in
            self.updateLabelAndFinishLoading(text: "No Internet Connection")
            self.isSending = false
        })
    }
    
    func signup() {
        if let user = username.text, let emailAddr = email.text,
           let pass = password.text {
            if user.count < 3 {
                label.text = "Username Taken"
                return
            }
            if user.count > 40 {
                label.text = "Username too long"
                return
            }
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            if !emailPred.evaluate(with: emailAddr) {
                label.text = "Invalid Email"
                return
            }
            if pass.count < 8 {
                label.text = "Password Shorter than 8"
                return
            }
            loading.startAnimating()
            isSending = true
            postJSON(url: register, json: ["username": user, "email": emailAddr, "password": pass], success: { data, res in
                // TODO: check more status code rather than just != 200
                if res.statusCode != 200 {
                    self.updateLabelAndFinishLoading(text: "Username or Email Already Exists")
                } else {
                    self.succeed(user: user, token: data, didSucceeded: self.didRegister)
                }
                self.isSending = false
            }, failure: { err in
                self.updateLabelAndFinishLoading(text: "No Internet Connection")
                self.isSending = false
            })
        } else {
            label.text = "All Fields Are Required"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == email {
            password.becomeFirstResponder()
        } else if textField == username {
            if button.currentTitle == "Login" {
                password.becomeFirstResponder()
            } else {
                email.becomeFirstResponder()
            }
        } else {
            if button.currentTitle == "Login" {
                login()
            } else {
                signup()
            }
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == password, let text = password.text, password.isSecureTextEntry {
            password.text?.removeAll()
            password.insertText(text)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.darkContent
    }
}
