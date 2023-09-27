//
//  UIViewControllerExtensions.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation
import ProgressHUD
import UIKit


extension UIViewController {
    func showLoading(_ showLoading: Bool, message: String? = nil) {
        if showLoading {
            ProgressHUD.show(message, interaction: false)
        } else {
            ProgressHUD.dismiss()
        }
    }
}
