//
//  UITableViewExtensions.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation
import UIKit

extension UITableView {
  func scrollToTop() {
      contentOffset = CGPoint(x: 0, y: -100)
  }
}
