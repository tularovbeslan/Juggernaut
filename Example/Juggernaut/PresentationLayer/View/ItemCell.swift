//
//  ItemCell.swift
//  Juggernaut_Example
//

import UIKit
import Juggernaut

class ItemCell: UITableViewCell {

	@IBOutlet weak var fileTypeImageView: UIImageView!
	@IBOutlet weak var name: UILabel!
	@IBOutlet weak var speed: UILabel!
	@IBOutlet weak var size: UILabel!
	@IBOutlet weak var percentage: UILabel!
	@IBOutlet weak var time: UILabel!
	@IBOutlet weak var progress: UIProgressView!

	func setup(_ item: Item) {

		name.text = item.name
		setupType(item.type)
	}

	func updateCellForRowAtIndexPath(_ indexPath : IndexPath, item: JuggernautItem) {

		updateProgress(item)
		updateLeftTime(item)
		updateSize(item)
		updateSpeed(item)
		updatePercentage(item)
	}

	fileprivate func setupType(_ type: String) {
		fileTypeImageView.image = UIImage(named: type)
	}

	fileprivate func updateProgress(_ item: JuggernautItem) {
		self.progress.progress = item.progress
	}

	fileprivate func updateLeftTime(_ item: JuggernautItem) {

		var timeLeft: String = ""

		guard let left = item.timeLeft else { return }

		if left.hours > 0 {
			timeLeft = "\(left.hours) Hours "
		}
		if left.minutes > 0 {
			timeLeft = timeLeft + "\(left.minutes) Min "
		}
		if left.seconds > 0 {
			timeLeft = timeLeft + "\(left.seconds) sec"
		}

		time.text = timeLeft
	}

	fileprivate func updateSize(_ item: JuggernautItem) {

		guard let downloadedSize = item.downloadedFile?.size else { return }
		guard let fullSize = item.file?.size else { return }
		guard let fullUnit = item.file?.unit else { return }

		let loaded = String(format: "%.2f", downloadedSize)
		let full = String(format: "%.2f", fullSize)
		size.text = "Size: \(loaded)/ \(full) \(fullUnit)"
	}

	fileprivate func updateSpeed(_ item: JuggernautItem) {

		guard let speedSize = item.speed?.speed else { return }
		guard let speedUnit = item.speed?.unit else { return }
		let duration = String(format: "%.2f", speedSize)
		speed.text = "Speed: \(duration) \(speedUnit)/s"
	}

	fileprivate func updatePercentage(_ item: JuggernautItem) {
		percentage.text = String(format: "%.f %%", item.progress * 100)
	}
}
