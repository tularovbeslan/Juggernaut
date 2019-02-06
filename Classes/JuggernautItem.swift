//
//  JuggernautItem.swift
//  Juggernaut
//

import Foundation

public enum JuggernautItemStatus: Int {

	case unknown
	case gettingInfo
	case downloading
	case paused
	case failed

	public func description() -> String {
		switch self {
		case .gettingInfo:
			return "GettingInfo"
		case .downloading:
			return "Downloading"
		case .paused:
			return "Paused"
		case .failed:
			return "Failed"
		default:
			return "Unknown"
		}
	}
}

open class JuggernautItem: NSObject {

	open var task: URLSessionDownloadTask?

	open var initialTime: Date?

	open var timeLeft: (hours: Int, minutes: Int, seconds: Int)?

	open var progress: Float = Float()

	open var speed: (speed: Float, unit: String)?

	open var name: String!

	open var url: String!

	open var status: String = JuggernautItemStatus.gettingInfo.description()

	open var file: (size: Float, unit: String)?

	open var downloadedFile: (size: Float, unit: String)?

	fileprivate(set) open var path: String = String()

	fileprivate convenience init(name: String, url: String) {

		self.init()
		self.name = name
		self.url = url
	}

	convenience init(name: String, url: String, path: String) {

		self.init(name: name, url: url)
		self.path = path
	}
}
