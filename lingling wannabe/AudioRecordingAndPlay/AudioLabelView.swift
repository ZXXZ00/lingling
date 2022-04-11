//
//  AudioLabelView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 4/3/22.
//

import UIKit

class AudioLabelView: UIView, UITextFieldDelegate {
    let label = UITextField()
    let title = UILabel()
    let button = UIButton()
    
    weak var controller: RecordingViewController?
    
    var suggestionsArray: [String] = []
    var audioFileTime: Int? = nil
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .white
        
        title.textColor = .black
        title.font = UIFont(name: "AmericanTypewriter", size: 16)
        title.text = "Create a label for the recording\n(e.g. Paganini Caprice No. 24)"
        title.numberOfLines = 2
        title.adjustsFontSizeToFitWidth = true
        addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        title.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.88).isActive = true
        title.heightAnchor.constraint(equalToConstant: 60).isActive = true
        NSLayoutConstraint(item: title, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 0.2, constant: 0).isActive = true
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 3, height: 40))
        leftView.backgroundColor = .white
        label.leftView = leftView
        label.leftViewMode = .always
        label.autocapitalizationType = .none
        label.textColor = .black
        label.backgroundColor = .white
        let font = UIFont(name: "AmericanTypewriter", size: 17)
        label.font = font
        label.layer.cornerRadius = 10
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.black.cgColor
        label.attributedPlaceholder = NSAttributedString(string: "name of the piece you just recorded", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: font]
        )
        label.delegate = self
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5).isActive = true
        label.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.88).isActive = true
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let config = UIImage.SymbolConfiguration(textStyle: .largeTitle, scale: .large)
        let checkIcon = UIImage(systemName: "checkmark", withConfiguration: config)?.withTintColor(.black, renderingMode: .alwaysOriginal)
        button.setImage(checkIcon, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(AudioLabelView.addLabel), for: .touchUpInside)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 40).isActive = true
        button.widthAnchor.constraint(equalToConstant: 80).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return !autoCompleteText(in: textField, using: string)
    }
    
    func autoCompleteText( in textField: UITextField, using string: String) -> Bool {
        if !string.isEmpty,
            let selectedTextRange = textField.selectedTextRange,
            selectedTextRange.end == textField.endOfDocument,
            let prefixRange = textField.textRange(from: textField.beginningOfDocument, to: selectedTextRange.start),
            let text = textField.text( in : prefixRange) {
            let prefix = text + string
            let matches = suggestionsArray.filter {
                $0.hasPrefix(prefix)
            }
            if (matches.count > 0) {
                textField.text = matches[0]
                if let start = textField.position(from: textField.beginningOfDocument, offset: prefix.count) {
                    textField.selectedTextRange = textField.textRange(from: start, to: textField.endOfDocument)
                    return true
                }
            }
        }
        return false
    }
    
    @objc func addLabel() {
        guard let time = audioFileTime, let labelText = label.text else { return }
        FilesManager.shared.addLabel(username: CredentialManager.shared.getUsername(), time: time, label: labelText)
        controller?.updateAndInsertRow(filename: "\(time).flac", label: labelText)
        removeFromSuperview()
        audioFileTime = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        endEditing(true)
    }
}
