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
		assert(identifier == sessionConfiguration.identifier, "Configuration identifiers do not match")
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
			var resumeDictionary : AnyObject!
			resumeDictionary = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil) as AnyObject
			var localFilePath = (resumeDictionary?["NSURLSessionResumeInfoLocalPath"] as? String)

			guard let localPath = localFilePath, localPath.count < 1 else {
				localFilePath = (NSTemporaryDirectory() as String) + (resumeDictionary["NSURLSessionResumeInfoTempFileName"] as! String)
				return false
			}

			let fileManager : FileManager! = FileManager.default
			debugPrint("resume data file exists: \(fileManager.fileExists(atPath: localFilePath! as String))")
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

		for (index, item) in self.items.enumerated() {

			if downloadTask.isEqual(item.task) {

				DispatchQueue.main.async(execute: { () -> Void in

					let receivedBytesCount = Double(downloadTask.countOfBytesReceived)
					let totalBytesCount = Double(downloadTask.countOfBytesExpectedToReceive)
					let progress = Float(receivedBytesCount / totalBytesCount)

					let initialTime = item.initialTime ?? Date()
					let timeInterval = initialTime.timeIntervalSinceNow
					let downloadTime = TimeInterval(-1 * timeInterval)

					let speed = totalBytesWritten / Int64(downloadTime)

					let remainingContentLength = totalBytesExpectedToWrite - totalBytesWritten

					let remainingTime = remainingContentLength / speed
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

					self.delegate?.juggernaut!(self, didUpdateProgress: item, forItemAt: index)
				})
				break
			}
		}
	}

	public func urlSession(_ session: URLSession,
												 downloadTask: URLSessionDownloadTask,
												 didFinishDownloadingTo location: URL) {

		for (index, item) in items.enumerated() {

			if downloadTask.isEqual(item.task) {

				guard let name = item.name else { return }
				let path = item.path == "" ? fileManager.documentDirectory() : item.path
				let destinationPath = path.appending(name)

				if fileManager.fileExists(atPath: path) {

					let fileURL = URL(fileURLWithPath: destinationPath as String)
					debugPrint("directory path = \(destinationPath)")
					do {

						try fileManager.moveItem(at: location, to: fileURL)
					} catch let error as NSError {

						debugPrint("Error while moving downloaded file to destination path:\(error)")
						DispatchQueue.main.async(execute: { () -> Void in
							self.delegate?.juggernaut!(self, didFail: item, forItemAt: index, with: error)
						})
					}
				} else {

					if let _ = self.delegate?.juggernaut?(self, notExist: location, forItem: item, at: index) {
						self.delegate?.juggernaut?(self, notExist: location, forItem: item, at: index)
					} else {

						let error = NSError(domain: "FolderDoesNotExist",
																code: 404,
																userInfo: [NSLocalizedDescriptionKey : "Destination folder does not exists"])
						self.delegate?.juggernaut?(self, didFail: item, forItemAt: index, with: error)
					}
				}

				break
			}
		}
	}

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

		debugPrint("task id: \(task.taskIdentifier)")
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
								self.delegate?.juggernaut?(self, didFinish: item, forItemAt: index)
							} else {
								self.delegate?.juggernaut?(self, didCancel: item, forItemAt: index)
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
								self.delegate?.juggernaut?(self, didFail: item, forItemAt: index, with: error)
							} else {
								let error: NSError = NSError(domain: "MZDownloadManagerDomain", code: 1000, userInfo: [NSLocalizedDescriptionKey : "Unknown error occurred"])
								self.delegate?.juggernaut?(self, didFail: item, forItemAt: index, with: error)
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
		debugPrint("All tasks are finished")
	}
}

extension Juggernaut {

	@objc public func addDownloadTask(_ name: String, request: URLRequest, path: String) {

		let url = request.url!.absoluteString

		let task = session.downloadTask(with: request)
		task.taskDescription = [name, url, path].joined(separator: ",")
		task.resume()

		debugPrint("session manager:\(String(describing: session)) url:\(String(describing: url)) request:\(String(describing: request))")

		let item = JuggernautItem.init(name: name, url: url, path: path)
		item.initialTime = Date()
		item.status = JuggernautItemStatus.downloading.description()
		item.task = task

		items.append(item)
		delegate?.juggernaut?(self, didStart: item, forItemAt: items.count - 1)
	}

	@objc public func addDownloadTask(_ name: String, fileURL: String, path: String) {

		let url = URL(string: fileURL)!
		let request = URLRequest(url: url)
		addDownloadTask(name, request: request, path: path)

	}

	@objc public func addDownloadTask(_ name: String, url: String) {
		addDownloadTask(name, fileURL: url, path: "")
	}

	@objc public func addDownloadTask(_ name: String, request: URLRequest) {
		addDownloadTask(name, request: request, path: "")
	}

	@objc public func pauseDownloadTaskAtIndex(_ index: Int) {

		let item = items[index]

		guard item.status != JuggernautItemStatus.paused.description() else { return }

		let task = item.task
		task!.suspend()
		item.status = JuggernautItemStatus.paused.description()
		item.initialTime = Date()

		items[index] = item

		delegate?.juggernaut?(self, didPaused: item, forItemAt: index)
	}

	@objc public func resumeDownloadTaskAtIndex(_ index: Int) {

		let item = items[index]

		guard item.status != JuggernautItemStatus.downloading.description() else { return }

		let task = item.task
		task!.resume()
		item.status = JuggernautItemStatus.downloading.description()

		items[index] = item

		delegate?.juggernaut?(self, didResume: item, forItemAt: index)
	}

	@objc public func retryDownloadTaskAtIndex(_ index: Int) {

		let item = items[index]
		guard item.status != JuggernautItemStatus.downloading.description() else { return }
		let task = item.task
		task!.resume()
		item.status = JuggernautItemStatus.downloading.description()
		item.initialTime = Date()
		item.task = task
		items[index] = item
	}

	@objc public func cancelTaskAtIndex(_ index: Int) {
		let info = items[index]
		let task = info.task
		task!.cancel()
	}

	@objc public func presentNotificationForDownload(_ notifAction: String, notifBody: String) {
		let application = UIApplication.shared
		let applicationState = application.applicationState

		if applicationState == UIApplication.State.background {
			let localNotification = UILocalNotification()
			localNotification.alertBody = notifBody
			localNotification.alertAction = notifAction
			localNotification.soundName = UILocalNotificationDefaultSoundName
			localNotification.applicationIconBadgeNumber += 1
			application.presentLocalNotificationNow(localNotification)
		}
	}
}
