//
//  GlobalExtensions.swift
//  MobileTest
//
//  Created by Anthony Tan on 9/27/23.
//

import Foundation

func mainAsync(execute work: @escaping @convention(block) () -> Void) {
    DispatchQueue.main.async(execute: work)
}
