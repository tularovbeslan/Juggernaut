//
//  FileManagerExtension.swift
//  Juggernaut
//

import Foundation

extension FileManager {

	private var kilobytes: Float64 { return 1024 }
	private var megabytes: Float64 { return pow(kilobytes, 2) }
	private var gigabytes: Float64 { return pow(kilobytes, 3) }

	public func documentDirectory() -> String {

		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		guard let path = paths.first else { return "" }
		return path
	}

	public func cachesDirectory() -> String {

		let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
		guard let path = paths.first else { return "" }
		return path
	}

	public func uniqueName(_ url: URL) -> String {

		var number: Int = 0
		var isUnique: Bool = false
		let ext = url.pathExtension
		let fullPath = url.deletingPathExtension()
		let name = fullPath.lastPathComponent
		var newName = name

		repeat {

			var path: String

			if ext.count > 0 {
				path = "\(documentDirectory())/\(newName).\(ext)"
			} else {
				path = "\(documentDirectory())/\(newName)"
			}

			let isAlreadyExists: Bool = FileManager.default.fileExists(atPath: path)

			if isAlreadyExists {

				number += 1
				newName = "\(name)(\(number))"
			} else {
				isUnique = true
				if ext.count > 0 {
					newName = "\(newName).\(ext)"
				}
			}

		} while isUnique == false

		return newName
	}

	public func freeDiskspace() -> NSNumber? {
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let systemAttributes: AnyObject?
		do {
			systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: paths.last!) as AnyObject?
			let freeSize = systemAttributes?[FileAttributeKey.systemFreeSize] as? NSNumber
			return freeSize
		} catch let error as NSError {
			debugPrint("Error Obtaining System Memory Info: Domain = \(error.domain), Code = \(error.code)")
			return nil
		}
	}

	public func size(_ length : Int64) -> Float {
		let data = Float64(length)
		if data >= gigabytes {
			return Float(data / gigabytes)
		} else if data >= megabytes {
			return Float(data / megabytes)
		} else if data >= kilobytes {
			return Float(data / kilobytes)
		} else {
			return Float(data)
		}
	}

	public func unit(_ length : Int64) -> String {
		let data = Float64(length)
		if data >= gigabytes {
			return Unit.GB.rawValue
		} else if data >= megabytes {
			return Unit.MB.rawValue
		} else if data >= kilobytes {
			return Unit.KB.rawValue
		} else {
			return Unit.Bytes.rawValue
		}
	}

	enum Unit: String {

		case GB
		case MB
		case KB
		case Bytes
	}
}

extension NSNotification.Name {

	public static let JuggernautDidFinishedDownloading = NSNotification.Name("JuggernautDidFinishedDownloading")
}
