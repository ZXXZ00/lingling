//
//  ToolBarView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/24/23.
//

import UIKit

class ToolBarView: UIView {
    
    let selectButton = UIButton()
    let exportButton = UIButton()
    let backButton = UIButton()
    let checkButton = UIButton()
    let deleteButton = UIButton()
    
    private let iconConfig = UIImage.SymbolConfiguration(textStyle: .largeTitle, scale: .small)
    
    weak var controller: VideoEditorViewController?
    
    private func styleTextButton(button: UIButton, text: String) {
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backButton.addTarget(controller, action: #selector(VideoEditorViewController.back), for: .touchUpInside)
        styleTextButton(button: backButton, text: "< bach")
        addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        backButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: VideoEditorViewController.TOOLBAR_WIDTH).isActive = true
        
        exportButton.addTarget(controller, action: #selector(VideoEditorViewController.exportVideo), for: .touchUpInside)
        styleTextButton(button: exportButton, text: "export")
        addSubview(exportButton)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        exportButton.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: VideoEditorViewController.BOT_PADDING).isActive = true
        exportButton.widthAnchor.constraint(equalToConstant: VideoEditorViewController.TOOLBAR_WIDTH).isActive = true
        
        selectButton.addTarget(controller, action: #selector(VideoEditorViewController.selectVideo), for: .touchUpInside)
        styleTextButton(button: selectButton, text: "select")
        addSubview(selectButton)
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        selectButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: VideoEditorViewController.BOT_PADDING).isActive = true
        selectButton.widthAnchor.constraint(equalToConstant: VideoEditorViewController.TOOLBAR_WIDTH).isActive = true
        
        checkButton.addTarget(controller, action: #selector(VideoEditorViewController.trimAsset), for: .touchUpInside)
        let checkmark = UIImage(systemName: "checkmark", withConfiguration: iconConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        checkButton.setImage(checkmark, for: .normal)
        checkButton.alpha = 0
        addSubview(checkButton)
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        checkButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        checkButton.widthAnchor.constraint(equalToConstant: VideoEditorViewController.TOOLBAR_WIDTH).isActive = true
        
        deleteButton.addTarget(controller, action: #selector(VideoEditorViewController.deleteAsset), for: .touchUpInside)
        let trash = UIImage(systemName: "trash.fill", withConfiguration: iconConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        deleteButton.setImage(trash, for: .normal)
        deleteButton.alpha = 0
        addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        deleteButton.bottomAnchor.constraint(equalTo: checkButton.topAnchor, constant: -VideoEditorViewController.BOT_PADDING).isActive = true
        deleteButton.widthAnchor.constraint(equalToConstant: VideoEditorViewController.TOOLBAR_WIDTH).isActive = true
    }
}
