//
//  FileManagerTests.swift
//  Juggernaut_Tests
//

import XCTest
import Foundation

class FileManagerTests: XCTestCase {

	private var sut: FileManager!
	private var kilobytes: Float64 { return 1024 }

    override func setUp() {
		sut = FileManager.default
	}

    override func tearDown() {
		sut = nil
	}

	func testReturnTotalSizeWhenGivenTotalBytesExpectedToWrite() {

		let size = sut.size(Int64(kilobytes * 5))
		XCTAssertEqual(size, 5, "Total size must be equal to 5")
	}

	func testReturnUnitForTotalSizeWhenGivenTotalBytesExpectedToWrite() {

		let unit = sut.unit(Int64(kilobytes * 5))
		XCTAssertEqual(unit, "KB", "Unit must be equal to KB")
	}

	func testUniqueNameIsUnique() {

		guard let url = URL(string: "https://www.test.com/4p/file.mp4?dl=1") else {
			XCTAssertTrue(true, "URL is wrong")
			return
		}
		let name = sut.uniqueName(url)
		XCTAssertEqual(name, "file3.mp4", "Name must be unique")
	}

	func testIsReturnFolderIsDocuments() {

		guard let folder = sut.documentDirectory().components(separatedBy: "/").last else {
			XCTAssertTrue(true, "Something with Documents folder went wrong!")
			return
		}
		XCTAssertEqual(folder, "Documents", "Folder must be Documents")
	}

	func testIsReturnFolderIsCaches() {

		guard let folder = sut.cachesDirectory().components(separatedBy: "/").last else {
			XCTAssertTrue(true, "Something with Caches folder went wrong!")
			return
		}
		XCTAssertEqual(folder, "Caches", "Folder must be Caches")
	}
}

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
