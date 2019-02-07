//
//  Network.swift
//  Juggernaut_Example
//
//  Created by workmachine on 07/02/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

protocol Network {
	func requestObject(_ url: URL, completion: @escaping ([Item]) -> ())
}
