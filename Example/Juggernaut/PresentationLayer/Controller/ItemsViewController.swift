//
//  ViewController.swift
//  Juggernaut
//

import UIKit
import Juggernaut

class ItemsViewController: UIViewController {

	// MARK: - IBOutlets

	@IBOutlet weak var indicator: UIView!
	@IBOutlet weak var tableView: UITableView!

	// MARK: - Properties

	var network: Network!
	var items: [Item] = []
	var fileManager: FileManager!
	var juggernaut: Juggernaut!

	// MARK: - Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		juggernaut = AppDelegate.shared.juggernaut
		juggernaut.delegate = self

		title = "Juggernaut"
		fileManager = FileManager.default
		setupTableView()
		network = NetworkImp()
		guard let url = URL(string: "https://gist.githubusercontent.com/tularovbeslan/96657a7b5f8f9d0fb34c6832e99e330f/raw/accecf19049728102a2d7c0e8c3fc6fde1f499c6/JSON%2520for%2520downloader") else { return }
		loadItems(url)
	}

	// MARK: - Helpers

	fileprivate func setupTableView() {

		tableView.delegate = self
		tableView.dataSource = self
		tableView.tableFooterView = UIView(frame: .zero)
		tableView.separatorStyle = .none
	}

	fileprivate func loadItems(_ url: URL) {

		indicator.isHidden = false
		network.requestObject(url) { [weak self] (items) in

			guard let `self` = self else { return }
			self.items = items
			DispatchQueue.main.async {

				self.indicator.isHidden = true
				self.tableView.reloadData()
			}
		}
	}

	fileprivate func refresh(_ item: JuggernautItem, atIndexPath indexPath: IndexPath) {

		guard let cell = self.tableView.cellForRow(at: indexPath) as? ItemCell else { return }
		cell.updateCellForRowAtIndexPath(indexPath, item: item)
	}
}

// MARK: - UITableViewDataSource

extension ItemsViewController: UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ItemCell.self), for: indexPath) as! ItemCell
		let item = items[indexPath.row]
		cell.setup(item)
		return cell
	}
}

// MARK: - UITableViewDelegate

extension ItemsViewController: UITableViewDelegate {

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)
		let item = items[indexPath.row]
		guard let url = URL(string: item.url) else { return }
		let name = fileManager.uniqueName(url)
		let path = fileManager.documentDirectory() + "/My Files"
		if juggernaut.items.contains(where: { $0.url == url.absoluteString }) {
			guard let index = juggernaut.items.firstIndex(where: { $0.path == path }) else { return }
			juggernaut.cancelTaskAtIndex(index)
		} else {
			juggernaut.addDownloadTask(name, fileURL: url, path: path, indexPath: indexPath, objects: nil)
		}
	}
}

// MARK: - JuggernautDelegate

extension ItemsViewController: JuggernautDelegate {

	func juggernaut(_ juggernaut: Juggernaut, didStart item: JuggernautItem, forItemAt indexPath: IndexPath, objects: [Any]?) {
		NotificationCenter.default.post(name: NSNotification.Name.JuggernautDidStart, object: item)
	}

	func juggernaut(_ juggernaut: Juggernaut, didPopulatedInterruptedTasks items: [JuggernautItem], objects: [Any]?) {

		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}

	func juggernaut(_ juggernaut: Juggernaut, didUpdateProgress item: JuggernautItem, forItemAt indexPath: IndexPath, objects: [Any]?) {

		DispatchQueue.main.async {

			self.refresh(item, atIndexPath: indexPath)
			NotificationCenter.default.post(name: NSNotification.Name.JuggernautDidUpdateProgress, object: item)
		}
	}

	func juggernaut(_ juggernaut: Juggernaut, didPaused item: JuggernautItem, forItemAt indexPath: IndexPath, objects: [Any]?) {

		DispatchQueue.main.async {

			self.refresh(item, atIndexPath: indexPath)
			NotificationCenter.default.post(name: NSNotification.Name.JuggernautDidPaused, object: item)
		}
	}

	func juggernaut(_ juggernaut: Juggernaut, didResume item: JuggernautItem, forItemAt indexPath: IndexPath, objects: [Any]?) {

		DispatchQueue.main.async {

			self.refresh(item, atIndexPath: indexPath)
			NotificationCenter.default.post(name: NSNotification.Name.JuggernautDidResume, object: item)
		}
	}

	func juggernaut(_ juggernaut: Juggernaut, didFinish item: JuggernautItem, forItemAt indexPath: IndexPath, objects: [Any]?) {

		let docDirectoryPath = fileManager.documentDirectory() + item.name
		NotificationCenter.default.post(name: NSNotification.Name.JuggernautDidFinish, object: docDirectoryPath)
	}

	func juggernaut(_ juggernaut: Juggernaut, didFail item: JuggernautItem, forItemAt indexPath: IndexPath, with error: NSError, objects: [Any]?) {

		print("didFail error \(error.localizedDescription)")
	}
}
