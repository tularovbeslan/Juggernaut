//
//  Network.swift
//  Juggernaut_Example
//

import Foundation

protocol Network {
	func requestObject(_ url: URL, completion: @escaping ([Item]) -> ())
}
