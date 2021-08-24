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
    
    let username = UITextField()
    let email = UITextField()
    let password = UITextField()
    let again = UITextField()
    let button = UIButton()
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(_ size: CGSize) {
        self.size = size
        floatViewDelegate = FloatView(size)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        username.bounds = CGRect(x: 0, y: 0, width: size.width/2, height: 40)
        username.center = CGPoint(x: size.width/2, y: size.height/2-90)
        username.textColor = .black
        username.backgroundColor = .white
        username.layer.cornerRadius = 10
        username.layer.borderWidth = 1
        username.layer.borderColor = UIColor.black.cgColor
        let usericon = UIImageView(image: UIImage(named: "user.pdf"))
        username.leftViewMode = .always
        username.leftView = usericon
        view.addSubview(username)
        
        email.bounds = CGRect(x: 0, y: 0, width: size.width/2, height: 40)
        email.center = CGPoint(x: size.width/2, y: size.height/2-30)
        email.textColor = .black
        email.backgroundColor = .white
        email.keyboardType = .asciiCapable
        email.layer.cornerRadius = 10
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.black.cgColor
        let emailicon = UIImageView(image: UIImage(named: "email.pdf"))
        email.leftViewMode = .always
        email.leftView = emailicon
        view.addSubview(email)
        
        password.bounds = CGRect(x: 0, y: 0, width: size.width/2, height: 40)
        password.center = CGPoint(x: size.width/2, y: size.height/2+30)
        password.textColor = .black
        password.backgroundColor = .white
        password.keyboardType = .asciiCapable
        password.layer.cornerRadius = 10
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.black.cgColor
        password.isSecureTextEntry = true
        password.leftViewMode = .always
        password.leftView = UIImageView(image: UIImage(named: "key.pdf"))
        view.addSubview(password)
        
        again.bounds = CGRect(x: 0, y: 0, width: size.width/2, height: 40)
        again.center = CGPoint(x: size.width/2, y: size.height/2+90)
        again.textColor = .black
        again.backgroundColor = .white
        again.keyboardType = .asciiCapable
        again.layer.cornerRadius = 10
        again.layer.borderWidth = 1
        again.layer.borderColor = UIColor.black.cgColor
        again.isSecureTextEntry = true
        again.leftViewMode = .always
        again.leftView = UIImageView(image: UIImage(named: "key.pdf"))
        again.attributedPlaceholder = NSAttributedString(string: "repeat the password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        view.addSubview(again)
        
        //button.bounds = CGRect(x: 0, y: 0, width: 80, height: 40)
        
        
        self.view = view
    }
}
