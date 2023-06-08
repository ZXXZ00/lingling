//
//  TrackViewControllerDelegate.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/24/23.
//

import Foundation

protocol TrackViewControllerDelegate: AnyObject {
    func didSelectView(view: TrackItemView)
    func didUnselect()
}
