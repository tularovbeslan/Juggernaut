//
//  Juggernaut.swift
//  Juggernaut
//

import Foundation
import UIKit

public class Juggernaut: NSObject, JuggernautDelegate {

	fileprivate var session: URLSession!

	fileprivate var fileManager: FileManager!

	fileprivate var backgroundSessionCompletionHandler: (() -> ())?

	fileprivate let nameIndex = 0

	fileprivate let urlIndex = 1

	fileprivate let destinationIndex = 2

	fileprivate weak var delegate: JuggernautDelegate?

	open var items: [JuggernautItem] = []

	public convenience init(session sessionIdentifer: String,
													delegate: JuggernautDelegate,
													sessionConfiguration: URLSessionConfiguration? = nil,
													completion: (() -> Void)? = nil) {

		self.init()
		self.delegate = delegate
		self.session = backgroundSession(identifier: sessionIdentifer, configuration: sessionConfiguration)
		self.populateOtherTasks()
		self.backgroundSessionCompletionHandler = completion
		self.fileManager = FileManager.default
	}

	public class func defaultSessionConfiguration(identifier: String) -> URLSessionConfiguration {
		return URLSessionConfiguration.background(withIdentifier: identifier)
	}

	fileprivate func backgroundSession(identifier: String, configuration: URLSessionConfiguration? = nil) -> URLSession {

		let sessionConfiguration = configuration ?? Juggernaut.defaultSessionConfiguration(identifier: identifier)
		let session = Foundation.URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
		return session
	}

	fileprivate func downloadTasks() -> [URLSessionDownloadTask] {

		var tasks: [URLSessionDownloadTask] = []
		let semaphore : DispatchSemaphore = DispatchSemaphore(value: 0)
		session.getTasksWithCompletionHandler { (_, _, downloadTasks) -> Void in

			tasks = downloadTasks
			semaphore.signal()
		}

		let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
		return tasks
	}

	fileprivate func populateOtherTasks() {

		let tasks = self.downloadTasks()

		for task in tasks {

			let taskComponents: [String] = task.taskDescription!.components(separatedBy: ",")
			let name = taskComponents[nameIndex]
			let url = taskComponents[urlIndex]
			let path = taskComponents[destinationIndex]

			let item = JuggernautItem.init(name: name, url: url, path: path)
			item.task = task
			item.initialTime = Date()

			if task.state == .running {

				item.status = JuggernautItemStatus.downloading.description()
				items.append(item)
			} else if(task.state == .suspended) {

				item.status = JuggernautItemStatus.paused.description()
				items.append(item)
			} else {
				item.status = JuggernautItemStatus.failed.description()
			}
		}
	}

	fileprivate func isValidResumeData(_ resumeData: Data?) -> Bool {

		guard let data = resumeData, data.count > 0 else { return false }

		do {
			var resume : AnyObject!
			resume = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil) as AnyObject
			var localFilePath = (resume?["NSURLSessionResumeInfoLocalPath"] as? String)

			guard let localPath = localFilePath, localPath.count < 1 else {
				localFilePath = (NSTemporaryDirectory() as String) + (resume["NSURLSessionResumeInfoTempFileName"] as! String)
				return false
			}

			let fileManager : FileManager! = FileManager.default
			return fileManager.fileExists(atPath: localFilePath! as String)
		} catch let error as NSError {
			debugPrint("resume data is nil: \(error)")
			return false
		}
	}
}

extension Juggernaut: URLSessionDownloadDelegate {

	public func urlSession(_ session: URLSession,
							 downloadTask: URLSessionDownloadTask,
							 didWriteData bytesWritten: Int64,
							 totalBytesWritten: Int64,
							 totalBytesExpectedToWrite: Int64) {

		for item in self.items {

			if downloadTask.isEqual(item.task) {

				DispatchQueue.main.async(execute: { () -> Void in

					let receivedBytesCount = Double(downloadTask.countOfBytesReceived)
					let totalBytesCount = Double(downloadTask.countOfBytesExpectedToReceive)
					let progress = Float(receivedBytesCount / totalBytesCount)

					let initialTime = item.initialTime ?? Date()
					let timeInterval = initialTime.timeIntervalSinceNow
					let downloadTime = TimeInterval(-1 * timeInterval)

					let speed = Float(totalBytesWritten) / Float(downloadTime)

					let remainingContentLength = totalBytesExpectedToWrite - totalBytesWritten

					let remainingTime = remainingContentLength / Int64(speed)
					let hours = Int(remainingTime) / 3600
					let minutes = (Int(remainingTime) - hours * 3600) / 60
					let seconds = Int(remainingTime) - hours * 3600 - minutes * 60

					let totalSize = self.fileManager.size(totalBytesExpectedToWrite)
					let totalSizeUnit = self.fileManager.unit(totalBytesExpectedToWrite)

					let downloadedSize = self.fileManager.size(totalBytesWritten)
					let downloadedSizeUnit = self.fileManager.unit(totalBytesWritten)

					let size = self.fileManager.size(Int64(speed))
					let unit = self.fileManager.unit(Int64(speed))

					item.timeLeft = (hours, minutes, seconds)
					item.file = (totalSize, totalSizeUnit as String)
					item.downloadedFile = (downloadedSize, downloadedSizeUnit as String)
					item.speed = (size, unit as String)
					item.progress = progress

					if self.items.contains(item), let objectIndex = self.items.index(of: item) {
						self.items[objectIndex] = item
					}

					self.delegate?.juggernaut!(self, didUpdateProgress: item, forItemAt: item.indexPath)
				})
				break
			}
		}
	}

	public func urlSession(_ session: URLSession,
												 downloadTask: URLSessionDownloadTask,
												 didFinishDownloadingTo location: URL) {

		for item in items {

			if downloadTask.isEqual(item.task) {

				guard let name = item.name else { return }
				let path = item.path == "" ? fileManager.documentDirectory() : item.path
				let destinationPath = path.appending(name)

				if fileManager.fileExists(atPath: path) {

					let fileURL = URL(fileURLWithPath: destinationPath as String)
					do {
						try fileManager.moveItem(at: location, to: fileURL)
					} catch let error as NSError {

						DispatchQueue.main.async(execute: { () -> Void in
							self.delegate?.juggernaut!(self, didFail: item, forItemAt: item.indexPath, with: error)
						})
					}
				} else {

					if let _ = self.delegate?.juggernaut?(self, notExist: location, forItem: item, at: item.indexPath) {
						self.delegate?.juggernaut?(self, notExist: location, forItem: item, at: item.indexPath)
					} else {

						let error = NSError(domain: "FolderDoesNotExist", code: 404, userInfo: [NSLocalizedDescriptionKey : "Destination folder does not exists"])
						self.delegate?.juggernaut?(self, didFail: item, forItemAt: item.indexPath, with: error)
					}
				}

				break
			}
		}
	}

	public func urlSession(_ session: URLSession,
												 task: URLSessionTask,
												 didCompleteWithError error: Error?) {

		DispatchQueue.main.async {

			let err = error as NSError?

			if (err?.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] as? NSNumber)?.intValue == NSURLErrorCancelledReasonUserForceQuitApplication || (err?.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] as? NSNumber)?.intValue == NSURLErrorCancelledReasonBackgroundUpdatesDisabled {

				let task = task as! URLSessionDownloadTask
				let taskComponents: [String] = task.taskDescription!.components(separatedBy: ",")
				let name = taskComponents[self.nameIndex]
				let url = taskComponents[self.urlIndex]
				let path = taskComponents[self.destinationIndex]

				let item = JuggernautItem.init(name: name, url: url, path: path)
				item.status = JuggernautItemStatus.failed.description()
				item.task = task

				let resumeData = err?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data

				var newTask = task
				if self.isValidResumeData(resumeData) == true {
					newTask = self.session.downloadTask(withResumeData: resumeData!)
				} else {
					newTask = self.session.downloadTask(with: URL(string: url as String)!)
				}

				newTask.taskDescription = task.taskDescription
				item.task = newTask

				self.items.append(item)

				self.delegate?.juggernaut?(self, didPopulatedInterruptedTasks: self.items)
			} else {

				for(index, item) in self.items.enumerated() {

					if task.isEqual(item.task) {

						if err?.code == NSURLErrorCancelled || err == nil {

							self.items.remove(at: index)

							if err == nil {
								self.delegate?.juggernaut?(self, didFinish: item, forItemAt: item.indexPath)
							} else {
								self.delegate?.juggernaut?(self, didCancel: item, forItemAt: item.indexPath)
							}

						} else {

							let resumeData = err?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
							var newTask = task

							if self.isValidResumeData(resumeData) == true {
								newTask = self.session.downloadTask(withResumeData: resumeData!)
							} else {
								newTask = self.session.downloadTask(with: URL(string: item.url)!)
							}

							newTask.taskDescription = task.taskDescription
							item.status = JuggernautItemStatus.failed.description()
							item.task = newTask as? URLSessionDownloadTask

							self.items[index] = item

							if let error = err {
								self.delegate?.juggernaut?(self, didFail: item, forItemAt: item.indexPath, with: error)
							} else {

								let error: NSError = NSError(domain: "JuggernautDownloadManagerDomain", code: 1000, userInfo: [NSLocalizedDescriptionKey : "Unknown error occurred"])
								self.delegate?.juggernaut?(self, didFail: item, forItemAt: item.indexPath, with: error)
							}
						}
						break;
					}
				}
			}
		}
	}

	public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {

		if let backgroundCompletion = self.backgroundSessionCompletionHandler {
			DispatchQueue.main.async(execute: {
				backgroundCompletion()
			})
		}
	}
}

extension Juggernaut {

	public func addDownloadTask(_ name: String, request: URLRequest, path: String, indexPath: IndexPath) {

		let url = request.url!.absoluteString

		let task = session.downloadTask(with: request)
		task.taskDescription = [name, url, path].joined(separator: ",")
		task.resume()

		let item = JuggernautItem.init(name: name, url: url, path: path)
		item.initialTime = Date()
		item.status = JuggernautItemStatus.downloading.description()
		item.task = task
		item.indexPath = indexPath
		items.append(item)
		delegate?.juggernaut?(self, didStart: item, forItemAt: item.indexPath)
	}

	public func addDownloadTask(_ name: String, fileURL url: URL, path: String, indexPath: IndexPath) {

		let request = URLRequest(url: url)
		addDownloadTask(name, request: request, path: path, indexPath: indexPath)
	}

	public func addDownloadTask(_ name: String, url: URL, indexPath: IndexPath) {
		addDownloadTask(name, fileURL: url, path: "", indexPath: indexPath)
	}

	public func addDownloadTask(_ name: String, request: URLRequest, indexPath: IndexPath) {
		addDownloadTask(name, request: request, path: "", indexPath: indexPath)
	}

	public func pauseDownloadTaskAtIndex(_ index: Int) {

		let item = items[index]

		guard item.status != JuggernautItemStatus.paused.description() else { return }

		let task = item.task
		task!.suspend()
		item.status = JuggernautItemStatus.paused.description()
		item.initialTime = Date()
		items[index] = item

		delegate?.juggernaut?(self, didPaused: item, forItemAt: item.indexPath)
	}

	public func resumeDownloadTaskAtIndex(_ index: Int) {

		let item = items[index]

		guard item.status != JuggernautItemStatus.downloading.description() else { return }

		let task = item.task
		task!.resume()
		item.status = JuggernautItemStatus.downloading.description()
		items[index] = item

		delegate?.juggernaut?(self, didResume: item, forItemAt: item.indexPath)
	}

	public func retryDownloadTaskAtIndex(_ index: Int) {

		let item = items[index]
		guard item.status != JuggernautItemStatus.downloading.description() else { return }
		let task = item.task
		task!.resume()
		item.status = JuggernautItemStatus.downloading.description()
		item.initialTime = Date()
		item.task = task
		items[index] = item
	}

	public func cancelTaskAtIndex(_ index: Int) {

		let info = items[index]
		let task = info.task
		task!.cancel()
	}
}
