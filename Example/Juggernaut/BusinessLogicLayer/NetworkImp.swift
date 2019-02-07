//
//  NetworkImp.swift
//  Juggernaut_Example
//
//  Created by workmachine on 07/02/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

class NetworkImp: Network {

	func requestObject(_ url: URL, completion: @escaping ([Item]) -> ()) {

		let sessionConfig = URLSessionConfiguration.default
		let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

		let task = session.dataTask(with: url) { (data, response, error) in
			let decoder = JSONDecoder()
			guard let jsonData = data else { return }
			let result = try! decoder.decode(Response.self, from: jsonData)
			let items = result.data
			completion(items)
		}
		task.resume()
	}
}
