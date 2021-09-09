//
//  LogintViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 7/4/21.
//

import UIKit

class LoginViewController: UIViewController {
    var size: CGSize
    var floatViewDelegate: FloatView?
    
    let label = UILabel()
    let username = UITextField()
    let email = UITextField()
    let password = UITextField()
    let again = UITextField()
    let button = UIButton()
    let guest = UIButton()
    
    let url = URL(string: "https://0j6a9nvvx3.execute-api.us-east-1.amazonaws.com/register")!
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(_ size: CGSize, isFullScreen: Bool=false) {
        self.size = size
        floatViewDelegate = FloatView(size)
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
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -250).isActive = true
        label.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5).isActive = true
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        username.textColor = .black
        username.backgroundColor = .white
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
        username.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -200).isActive = true
        username.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5).isActive = true
        username.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        email.textColor = .black
        email.backgroundColor = .white
        email.keyboardType = .asciiCapable
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
        email.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5).isActive = true
        email.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        password.textColor = .black
        password.backgroundColor = .white
        password.keyboardType = .asciiCapable
        password.layer.cornerRadius = 10
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.black.cgColor
        password.isSecureTextEntry = true
        password.leftViewMode = .always
        password.leftView = UIImageView(image: UIImage(named: "key.pdf"))
        password.attributedPlaceholder = NSAttributedString(string: "minimum length 8", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        view.addSubview(password)
        password.translatesAutoresizingMaskIntoConstraints = false
        password.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        password.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -100).isActive = true
        password.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5).isActive = true
        password.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        again.textColor = .black
        again.backgroundColor = .white
        again.keyboardType = .asciiCapable
        again.layer.cornerRadius = 10
        again.layer.borderWidth = 1
        again.layer.borderColor = UIColor.black.cgColor
        again.isSecureTextEntry = true
        again.leftViewMode = .always
        again.leftView = UIImageView(image: UIImage(named: "key.pdf"))
        again.attributedPlaceholder = NSAttributedString(string: "repeat the password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        view.addSubview(again)
        again.translatesAutoresizingMaskIntoConstraints = false
        again.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        again.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -50).isActive = true
        again.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5).isActive = true
        again.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(register), for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 70).isActive = true
        button.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.22).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        guest.setTitle("Continue as Guest", for: .normal)
        guest.setTitleColor(.black, for: .normal)
        guest.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        guest.addTarget(self, action: #selector(asGuest), for: .touchUpInside)
        view.addSubview(guest)
        guest.translatesAutoresizingMaskIntoConstraints = false
        guest.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        guest.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        guest.widthAnchor.constraint(equalToConstant: 120).isActive = true
        guest.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }
    
    @objc func asGuest() {
        UserDefaults.standard.set("guest", forKey: "username")
        dismiss(animated: true)
    }
    
    @objc func register() {
        if let user = username.text, let emailAddr = email.text,
           let pass = password.text, let rep = again.text {
            if user.count < 3 {
                label.text = "Username Taken"
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
            if pass != rep {
                label.text = "Password Did Not Match"
                return
            }
            let loading = UIActivityIndicatorView(style: .large)
            loading.center = view.center
            view.addSubview(loading)
            loading.startAnimating()
            postJSON(url: url, json: ["username": user, "email": emailAddr, "password": pass], success: { code, res in
                // Need to do more
                if res.statusCode != 200 {
                    DispatchQueue.main.async {
                        self.label.text = "Username or Email Already Exists"
                        loading.stopAnimating()
                    }
                } else {
                    UserDefaults.standard.set(user, forKey: "username")
                    DispatchQueue.main.async {
                        self.dismiss(animated: true)
                    }
                }
            }, failure: {err in print("oh no")})
        } else {
            label.text = "All Fields Are Required"
        }
        //dismiss(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.darkContent
    }
}
